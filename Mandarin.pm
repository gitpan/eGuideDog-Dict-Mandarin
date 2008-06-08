package eGuideDog::Dict::Mandarin;

use strict;
use warnings;
use utf8;
use Encode::CNMap;
use Storable;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use eGuideDog::Dict::Mandarin ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.43';


# Preloaded methods go here.

sub new() {
  my $self = {};
  $self->{pinyin} = {}; # The most probably phonetic symbol
  $self->{chars} = {}; # all phonetic symbols (array ref)
  $self->{words} = {}; # word phonetic symbols (array ref)
  $self->{word_index} = {}; # the first char to words (array ref)
  bless $self, __PACKAGE__;

  # load dictionary file.
  my $dir = __FILE__;
  $dir =~ s/[.]pm$//;

  if(-e "$dir/Mandarin.dict") {
    my $dict = retrieve("$dir/Mandarin.dict");
    $self->{pinyin} = $dict->{pinyin};
    $self->{chars} = $dict->{chars};
    $self->{words} = $dict->{words};
    $self->{word_index} = $dict->{word_index};
  }

  return $self;
}

sub update_dict {
  my $self = shift;

  $self->{pinyin} = {};
  $self->{chars} = {};
  $self->{words} = {};
  $self->{word_index} = {};

  $self->import_zh_list("zh_list");
  $self->import_zh_list("zh_listx");

  my $dict = {pinyin => $self->{pinyin},
	      chars => $self->{chars},
	      words => $self->{words},
	      word_index => $self->{word_index},
	     };
  store($dict, "Mandarin.dict");
}

sub add_symbol {
  my ($self, $char, $symbol) = @_;

  if (not $self->{chars}->{$char}) {
    $self->{chars}->{$char} = [$symbol];
    return 1;
  } else {
    foreach (@{$self->{chars}->{$char}}) {
      if ($symbol eq $_) {
	return 0;
      }
    }
    $self->{chars}->{$char} = [@{$self->{chars}->{$char}}, $symbol];
    return 1;
  }
}

sub import_zh_list {
    my ($self, $zh_list) = @_;

    open(ZH_LIST, '<:utf8', $zh_list);
    while (my $line = <ZH_LIST>) {
        if ($line =~ /^(.)\s([^\s]*)\s$/) {
            if ($1 && $2) {
                $self->{pinyin}->{$1} = $2;
                $self->add_symbol($1, $2);
            }
        } elsif ($line =~ /^[(]([^)]*)[)]\s([^\s]*)\s$/) {
            my @chars = split(/ /, $1);
            my $phon = $2;
            my @symbols;
            if ($phon =~ /[|]/) {
                @symbols = split(/[|]/, $phon);
            } else {
                while($phon && $phon =~ /^([a-z]*[0-9])(.*)/) {
                    push(@symbols, $1);
                    $phon = $2;
                }
            }
            if ($#chars != $#symbols) {
                warn "Dictionary error:" . "@chars" . "-" . "@symbols";
                next;
            }
            my $word = join("", @chars);
            if ($self->{word_index}->{$chars[0]}) {
                push(@{$self->{word_index}->{$chars[0]}}, $word);
            } else {
                $self->{word_index}->{$chars[0]} = [$word];
            }
            $self->{words}->{$word} = \@symbols;
            for (my $i = 0; $i <= $#chars; $i++) {
                $self->add_symbol($chars[$i], $symbols[$i]);
            }
        }
    }
    close(ZH_LIST);
}

sub get_pinyin {
  my ($self, $str) = @_;

  if (not utf8::is_utf8($str)) {
    if (not utf8::decode($str)) {
      warn "$str is not in utf8 encoding.";
      return undef;
    }
  } elsif (not $str) {
    return undef;
  }

  if (wantarray) {
    my @pinyin;
    for (my $i = 0; $i < length($str); $i++) {
      my $char = substr($str, $i, 1);
      my @words = $self->get_words($char);
      my $longest_word = '';
      foreach my $word (@words) {
	if (index($str, $word) == 0) {
	  if (length($word) > length($longest_word)) {
	    $longest_word = $word;
	  }
	}
      }
      if ($longest_word) {
	push(@pinyin, @{$self->{words}->{$longest_word}});
	$i += $#{$self->{words}->{$longest_word}};
      } else {
	push(@pinyin, $self->{pinyin}->{$char});
      }
    }
    return @pinyin;
  } else {
    my $char = substr($str, 0, 1);
    my @words = $self->get_words($char);
    my $longest_word = '';
    foreach my $word (@words) {
      if (index($str, $word) == 0) {
	if (length($word) > length($longest_word)) {
	  $longest_word = $word;
	}
      }
    }
    if ($longest_word) {
      return $self->{words}->{$longest_word}->[0];
    } else {
      return $self->{pinyin}->{$char};
    }
  }
}

sub get_words {
  my ($self, $char) = @_;

  if ($self->{word_index}->{$char}) {
    return @{$self->{word_index}->{$char}};
  } else {
    return ();
  }
}

sub is_multi_phon {
  my ($self, $char) = @_;
  return $#{$self->{chars}->{$char}};
}

sub get_multi_phon {
  my ($self, $char) = @_;
  if ($self->{chars}->{$char}) {
    return @{$self->{chars}->{$char}};
  } else {
    return undef;
  }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

eGuideDog::Dict::Mandarin - an informal Pinyin dictionary.

=head1 SYNOPSIS

  use utf8;
  use eGuideDog::Dict::Mandarin;

  binmode(stdout, 'utf8');
  my $dict = eGuideDog::Dict::Mandarin->new();
  my $symbol = $dict->get_pinyin("长");
  print "长: $symbol\n";
  $symbol = $dict->get_pinyin("长江");
  print "长江的长: $symbol\n";
  my @symbols = $dict->get_pinyin("拼音");
  print "拼音: @symbols\n";
  my @words = $dict->get_words("长");
  print "Some words begin with 长: @words\n";

=head1 DESCRIPTION
This module is for looking up Pinyin of Mandarin characters or words. The dictionary is from Mandarin dictionary of espeak (http://espeak.sf.net), which is mainly from Unihan is CEDICT. It's a part of the eGuideDog project (http://e-guidedog.sf.net).

=head2 EXPORT

None by default.

=head1 METHODS

=head2 new()

Initialize dictionary.

=head2 get_pinyin($str)

Return a scalar of Pinyin phonetic symbol of the first character if it is in a scalar context.

Return an array of Pinyin phonetic symbols of all characters in $str if it is in an array context.

=head2 get_words($char)

Return an array of words which are begined with $char. This list of words contains multi-phonetic-symbol characters and the symbol used in the word is less frequent than the other.

=head2 is_multi_phon($char)

Return non-zero if $char is multi-phonetic-symbol character. The returned value plus 1 is the number of phonetic symbols the character has.

Return 0 if $char is single-phonetic-symbol character.

=head2 get_multi_phon($char)

Return an array of phonetic symbols of $char.

=head1 SEE ALSO

L<eGuideDog::Dict::Cantonese>, L<http://e-guidedog.sf.net>

=head1 AUTHOR

Cameron Wong, E<lt>hgn823-perl at yahoo.com.cnE<gt>

=head1 ACKNOWLEDGMENT

Thanks to Silas S. Brown (http://people.pwf.cam.ac.uk/ssb22/) for maintaining the Mandarin dictionary file.

=head1 COPYRIGHT AND LICENSE

=over 2

=item of the module

Copyright 2008 by Cameron Wong

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=item of the dictionary data

Unihan and CC-CEDICT are used in the dictionary data.

About Unihan: Copyright (c) 1996-2006 Unicode, Inc. All Rights reserved.

  Name: Unihan database
  Unicode version: 5.0.0
  Table version: 1.1
  Date: 7 July 2006

CC-CEDICT is licensed under a Creative Commons Attribution-Share Alike 3.0 License.  http://www.mdbg.net/chindict/chindict.php?page=cedict

CC-CEDICT is a continuation of the CEDICT project started by Paul Denisowski in 1997 with the aim to provide a complete downloadable Chinese to English dictionary with pronunciation in pinyin for the Chinese characters.

=back

=cut
