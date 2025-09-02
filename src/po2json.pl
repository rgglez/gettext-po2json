#!/usr/bin/perl

###############################################################################
#   Copyright 2025 Rodolfo González González <code@rodolfo.gg>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
###############################################################################

use strict;
use warnings;
use JSON::PP;
use Locale::PO;
use Getopt::Long;
use File::Temp qw(tempfile);
use utf8;
use Encode qw(decode encode);
use open ':std', ':encoding(UTF-8)';

# The input PO file
my $po_file = '';

# The output JSON file
my $json_file = '';

# dDefault context
my $default_context = 'app';

GetOptions ("po=s" => \$po_file,
            "json=s" => \$json_file,
            "context=s" => \$default_context)
or die("Error in command line arguments\n");

# Does the PO file exist?
die "PO file not found: $po_file\n" unless -f $po_file;

# Read the PO file in UTF-8 encodding
open my $po_fh, '<:encoding(UTF-8)', $po_file or die "Unable to read $po_file: $!\n";
my $po_content = do { local $/; <$po_fh> };
close $po_fh;

# Temporary file for Locale::PO
my ($temp_fh, $temp_file) = tempfile(SUFFIX => ".$po_file.tmp");
print $temp_fh encode('UTF-8', $po_content);

# Load PO data
my $po_data = Locale::PO->load_file_asarray($temp_file);
close($temp_fh); # clean up temporary file

die "Error reading PO file\n" unless $po_data;

# Struct for the JSON
my $json_output = {
    charset => 'utf-8',
    headers => {},
    translations => {}
};

# Process each PO entry
foreach my $po_entry (@$po_data) {
    my $msgid = $po_entry->msgid || '';
    my $msgstr = $po_entry->msgstr || '';
    my $msgctxt = $po_entry->msgctxt || '';

    # Cleanup
    $msgid = clean_po_string($msgid);
    $msgstr = clean_po_string($msgstr);
    $msgctxt = clean_po_string($msgctxt);

    # Which is the context?
    my $context = $msgctxt || $default_context;

    # Init the context
    $json_output->{translations}->{$context} = {} unless exists $json_output->{translations}->{$context};

    # Process empty entry (headers)
    if ($msgid eq '' && $msgstr ne '') {
        # Parse msgstr headers
        my @header_lines = split /\\n/, $msgstr;
        foreach my $line (@header_lines) {
            next unless $line =~ /^([^:]+):\s*(.*)$/;
            my ($key, $value) = ($1, $2);
            $key =~ s/^\s+|\s+$//g;  # trim
            $value =~ s/^\s+|\s+$//g;  # trim
            $json_output->{headers}->{$key} = $value if $key && defined $value;
        }

        # Add meta data to empty context
        $json_output->{translations}->{''}->{''} = {
            msgid => '',
            msgstr => [$msgstr]
        };
    }
    # Process normal entry
    elsif ($msgid ne '') {
        my $entry = {
            msgid => $msgid,
            msgstr => [$msgstr]
        };

        # Add context only if it exists
        $entry->{msgctxt} = $context if $context ne '';

        # Handle plurals
        if ($po_entry->msgid_plural) {
            my $msgid_plural = clean_po_string($po_entry->msgid_plural || '');
            $entry->{msgid_plural} = $msgid_plural;

            # Get all the plural forms
            my @plural_forms = ();
            for my $i (0..10) {  # max 10 plural forms
                my $plural_str = $po_entry->msgstr_n->{$i};
                last unless defined $plural_str;
                $plural_str = clean_po_string($plural_str);
                push @plural_forms, $plural_str;
            }
            $entry->{msgstr} = \@plural_forms if @plural_forms;
        }

        # Add the entry to the JSON output under "translations"
        $json_output->{translations}->{$context}->{$msgid} = $entry;
    }
}

# Ensure the output has the basic headers
unless (keys %{$json_output->{headers}}) {
    $json_output->{headers} = {
        'Project-Id-Version' => '',
        'POT-Creation-Date' => '',
        'PO-Revision-Date' => '',
        'Last-Translator' => '',
        'Language-Team' => '',
        'Language' => '',
        'MIME-Version' => '1.0',
        'Content-Type' => 'text/plain; charset=UTF-8',
        'Content-Transfer-Encoding' => '8bit',
        'Plural-Forms' => '',
        'X-Generator' => ''
    };
}

# Generate the output preserving the UTF-8 encoding
my $json = JSON::PP->new->utf8(0)->pretty;
my $json_string = $json->encode($json_output);

# Write to the output file
open my $fh, '>:encoding(UTF-8)', $json_file or die "Unable to write to $json_file: $!\n";
print $fh $json_string;
close $fh;

print "File sucessfully converted: $json_file\n";

###############################################################################
# Utility functions

# Clean and decode PO strings
sub clean_po_string {
    my ($str) = @_;
    return '' unless defined $str;

    # Clean external quotes
    $str =~ s/^"(.*)"$/$1/s;

    # Decode escape sequences
    $str =~ s/\\n/\n/g;
    $str =~ s/\\t/\t/g;
    $str =~ s/\\r/\r/g;
    $str =~ s/\\\\/\\/g;
    $str =~ s/\\"/"/g;

    # Ensure it is a valid UTF-8 string
    if (!utf8::is_utf8($str)) {
        # Try to decode from UTF-8 if it is not marked as such
        eval { $str = decode('UTF-8', $str, Encode::FB_CROAK); };
        if ($@) {
            # Last resource: latin1
            eval { $str = decode('latin1', $str); };
        }
    }

    return $str;
}
