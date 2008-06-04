use strict;
use Storable;

# init dictionary
my $dict = {pinyin => {},
    chars => {},
    words => {},
    word_index => {},
};
store($dict, "Mandarin.dict");

use eGuideDog::Dict::Mandarin;
$dict=eGuideDog::Dict::Mandarin->new();
$dict->update_dict();

