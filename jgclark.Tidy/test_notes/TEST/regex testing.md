# Regex TEST
#ignore
> @[\w\d\/]+?\([\w\d\-\/\.]*?\)|@[\w\d\/]+
seems to work for simple tags: @tag. @tag: @bother! "@drat" @really? -@ignore. '@me'
For tags with parameters: @ztag(date) (@ztag(2020-10-04)) @ztag() @ztag(12th) @ztag(12.12.2020)
Even with slash terms: @ztag/subtag and @ztag/subtag(test)
But need to ignore me@mac.com and bob.smith@me.org.uk.
> \#[\w\d\/_]+  doesn't work on all the following in Expressions
> \#[^\s\'\;\:\"\<\>\,\.\(\)\*\?\[\]\{\}\^\$\|\!]+  but seems to in Expressions
Works for hashtags excluding only all-digit #ztest  #ztest123  #123ztest  #123
But should break on punctuation: "#ztest", #ztest123:  *#ztest* #ztest? |#ztest| <#ztest> [#ztest] {#ztest^ !#ztest? 
Except #zthis_and_that and #zzz/yyy.
Emojis though? #🥖/lunch👨‍👧‍👧🤲👐🙌👏/mouthful.
> Eduard has found (@[^[:punct:][:space:]]+?\\(.*?\\)|@[^[:punct:][:space:]]+) prepended this: (\\s|^|\\\”|\\’|\\(|\\[|\\{), but this doesn’t work perfectly for me.
