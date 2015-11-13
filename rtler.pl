#!/usr/bin/perl
use Term::ANSIColor;

#
# Author: Hadeer Younis
# Description: This script take multiple files as input and flips their CSS
# Usage: 
#   ./make_rtl.pl file_1.css file_2.css [--output] [--override] [--class-prefix]
#   ./make_rtl.pl --staged [--output] [--override] [--class-prefix]
#   ./make_rtl.pl dir1/ dir2/ file_1.css file_2.css
#
# params:
#   class-prefix: 
#     Is a comma seperated string of class names, which the generated selectors are prefixed with
#
#   output:
#     1: Output RTL CSS to console
#     0: Write RTL CSS to file
#  
#   override:
#     1: RTL CSS is meant to override CSS
#     0: RTL CSS is meant to replace LTR CSS
#  
#   staged:
#     1: Apply script on changes staged for commit
#     0: Apply on all CSS files in @ARGS 
#
#   silent:
#     1: Don't print anything
#     0: Print things

use File::Slurp;
use Getopt::Long;

my $override = 0;
my $silent = 0;
my $output = 0;
my $staged = 0;
my $class_prefix = 0;
my @class_prefixes = [];

GetOptions ("class-prefix=s" => \$class_prefix, "output!" => \$output, "override!" => \$override, , "staged!" => \$staged, "silent!" => \$silent);

my %subs = (
    right => "left",
    left  => "right",
    rtl   => "ltr",
    ltr   => "rtl"
);

my %neuteralizers = (
    color => "transparent",
    style => "none",
    width => "0",
    radius => "0"
);

my %overrides = (
    qw/([\\w-]+)(right|left)([\\w-]+)(width|radius|color|style):\\s*([^;]+|[^\\n]+)/ => '"$1$2$3$4: $neuteralizers{$4}"',
    qw/([\\w-]+)(right|left):\\s*([^;]+|[^\\n]+)/ => '"$1$2: 0"',
    qw/(\\s*)(right|left):\\s*([^;]+|[^\\n]+)/ => '"$1$2: auto"',
);

# These are the regexs that do the actual flipping
my @regexs = (
    qw/(border-radius):\\s*(\\w+)\\h(\\w+)\\h(\\w+)\\h(\\w+)/,
    qw/(border-radius):\\s*(\\w+)\\h(\\w+)\\h(\\w+)[\\h;]*/,
    qw/(border-\\w+):\\s*(\\w+)\\h(\\w+)\\h(\\w+)\\h(\\w+)/,
    qw/(border-)(\\w+):\\s*(\\w+)\\h(\\w+)\\h(\\w+)[\\h;]*/,
    qw/(margin|padding):\\s*(\\w+)\\h(\\w+)\\h(\\w+)\\h(\\w+)/,
    qw/(margin|padding):\\s*(\\w+)\\h(\\w+)\\h(\\w+)[\\h;]*$/,
    qw/([-\\w:]*)(right|left|ltr|rtl)([-\\w:]*)/,
);

# These are the regexs that do the actual flipping
my @regex_subs = (
    '"$1: $3 $2 $5 $4"',
    '"$1: $3 $2 0 $4;"',
    '"$1: $4 $5 $2 $3"',
    '"$1$2: $5 $neuteralizers{$2} $3 $4;"',
    '"$1: $2 $5 $4 $3"',
    '"$1: $2 0 $4 $3;"',
    '"$1$subs{$2}$3"',
);

sub process_css {
    my $input_file_text = @_[0];
    my $output_file_text = "";

    # This regex matches CSS rules with all preceding comments
    # 
    # Example:
    # /*@ignore*/ #main {
    #   font-size: 20px;
    # }
    my @rules = $input_file_text =~ /(?:\/\*[^*]*\*+(?:[^\/*][^*]*\*+)*\/|\s*\/\/[^\n]+)?(\s*\@(?:keyframe|media|-)[^{]+{[\s\S]+?}\s*}|[^{}]+{[^{}]*})?/g;

    RULES:foreach(@rules) {
        # Checks if it is a media query
        if(/\@(keyframe|media|-)/) {
            my @breakdown = /(\/\*[^*]*\*+(?:[^\/*][^*]*\*+)*\/|\s*\/\/[^\n]+)?(\s*\@(?:keyframe|media|-)[^{]+)({\s*)([\s\S]+?})(\s*})/;

            $output_file_text .= $1 . $2 . $3 . &process_css($4) . $5;
            next RULES;
        }

        # This breaks down the rule to:
        #   1. Preceding comments
        #   2. Selector
        #   3. {
        #   4. The actual CSS
        #   5. }
        my @breakdown = /([^{]+\*\/\s*|\s*\/\/[^\n]+)?([^{}]+?)(\s*{ *\n*)([^{}]+?)(\s*}\s*)/;

        # This checks if the rule should be ignored.
        # Possible scenarios:
        #   1. /*@noflip*/
        #   2. .lang_is_rtl
        #   3. .rtl
        #   4. .ar
        #   5. .he
        if (@breakdown[0] =~ /\@noflip/ || @breakdown[1] =~ /(\.lang_is_rtl|\.ar|\.he|\.rtl)[\s\n,{]+/) {
            next;
        }

        # This creates an array containing the attributes
        my @attributes = @breakdown[3] =~ /(.+(?=:):(?<=:)[^;}]+;?)/g;
        my $new_css = "";

        # This processes each attributes
        ATTRIBUTES:foreach(@attributes) {
            my $attribute = $_;
            my $override_attribute = $_;
            # If it's a replace then do it
            if(/\@replace/) {
                $attribute = $_ =~ s/:([^;]+)(?=\/\*\s*\@replace)(.*)(?<=\/\*\@replace:)(.*)(\*\/\w*;?)/:$3$2$1$4/;
            }

            # If it's not an ignore then try to flip
            if(not /\@noflip/) {
                # This does the flipping part
                MATCH:for my $index (0 .. $#regexs)
                {
                    $_ =~ s/@regexs[$index]/@regex_subs[$index]/eeg;
                    last MATCH if $_ ne $attribute;
                }
            }

            # Do not append unflipped CSS if we are overriding
            if($attribute ne $_ or not $override) {

                # Checks if it should neutralize the CSS it is overriding
                if($override and /(left|right)+[-:\w]+/) {
                    OVERRIDE: for my $sub (keys %overrides) {
                        if(/$sub/) {
                            $override_attribute =~ s/$sub/$overrides{$sub}/eeg;
                            last OVERRIDE;
                        }
                    }

                    if($override_attribute ne $attribute) {
                        $new_css = $new_css . $override_attribute . "\n";
                    }
                }
                    
                $new_css .= $_ . "\n";
            }
        }

        # Do not append empty text
        if(not $new_css eq "") {
            my $new_selector = @breakdown[1];

            # This adds language specific class prefixes if defined in arguments
            if($class_prefix) {
                $new_selector =~ s/^\s+|\s+$//g;
                my @selectors = $new_selector =~ /([^,]+)/g;
                $new_selector = "";
                
                foreach(@class_prefixes) {
                    my $prefix = $_;

                    foreach(@selectors) {
                        if($new_selector ne "") {
                            $new_selector = "$new_selector,\n";
                        }
                    
                        $_ =~ s/^\s+|\s+$//g;
                        $new_selector = "$new_selector$prefix $_";
                    }
                }
            }

            $output_file_text .= "@breakdown[0]$new_selector@breakdown[2]$new_css@breakdown[4]";
        }
    }
    return $output_file_text;
}

sub process_files {
    my $dir = @_[0];
    opendir(DIR, $dir) or die $!;
    
    while (my $file = readdir(DIR)) {
        # skip if starts with .
        next if ($file =~ m/^\./);

        # Check if folder
        if( -d ("$dir/$file")) {
            #&process_files("$dir$file/");
        } else {
            # ignore RTL CSS files & NON CSS files
            next if ($file =~ m/\.rtl\.css/ or !($file =~ m/\.css/));
            &process_file("$dir/$file");
        }
    }

    closedir(DIR);
}

sub process_file {
    my $file = @_[0]; 
    my $css = read_file($file);
    (my $output_content = &process_css($css)) =~ s/^\s+|\s+$//g;
    
    if($output_content eq "") {
        print colored(['white'], "$file");
        print colored(['red'], " => Nothing to flip!");
        return;
    }  
    
    if($output) {
        print $output_content;
    } else {
        $file =~ s/\.css/.rtl.css/;
        print colored(['white'], "$file");
        print colored(['green'], " => $file\n");
        write_file($file, $output_content);
    }
}

sub init {
    my @files_to_flip = @ARGV;

    if($staged) {
        my $files = `git diff --diff-filter=MA HEAD -- *.{css,scss,sass}`;
        @files_to_flip = $files =~ /([^\n]*\n)/g;
    }

    if($class_prefix) {
        @class_prefixes = $class_prefix =~ /([^,]+)/g;
    }
    foreach(@files_to_flip) {
        if (-d $_) {
            &process_files($_);
        }
        else {
            &process_file($_);
        }
    }
}

&init();
