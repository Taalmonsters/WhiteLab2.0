# Usage
=======

## Explore

Within the *Explore* interface, URL parameters may be passed to the statistics page, the n-grams page, or the document page. The statistics page is accessible through:

- /whitelab/explore/statistics

and accepts the following paramaters:

- metadata: Metadata filters are **required** for corpus statistics. Each field may be used multiple times and accepts literal values only. Prefix a value with '-' to exclude it (for example: CollectionName=-Newspapers). Values consisting of multiple tokens should be surrounded with quotes (CollectionName="Discussion lists").
- **tab**: Optional. Defines the type of results to be displayed: 'freqlist' for frequency list (default), 'doclist' for document list, 'growth' for vocabulary growth, 'wordcloud' for the word cloud.
- **group**: Optional. Can only be used in combination with 'tab=freqlist' or 'tab=wordcloud'. The following values can be used as input:
  - hit:word
  - hit:lemma
  - hit:pos

The n-grams page is accessible through:

- /whitelab/explore/ngrams

and accepts the following parameters:

- **query**: Your query formatted in Corpus Query Language. It should contain up to five token positions, which are denoted by square brackets []. Each token may be left blank, or filled with a word, lemma, or pos query. For example: [lemma="de"][word="ge.*"][pos="N.*"], or: [][pos="ADJ.*"][]
- metadata: Optional. Each field may be used multiple times and accepts literal values only. Prefix a value with '-' to exclude it (for example: CollectionName=-Newspapers). Values consisting of multiple tokens should be surrounded with quotes (CollectionName="Discussion lists").
- **group**: Optional. The following values can be used as input:
  - hit:word
  - hit:lemma
  - hit:pos

The document page is accessible through:

- /whitelab/explore/document

and accepts only a single parameter:

- **docpid**: Required. Unique id for a document in the corpus.
- **tab**: Optional. Defines the type of results to be displayed: 'text' for document contents (default), 'metadata' for document metadata, 'statistics' for document statistics, 'wordcloud' for the document word cloud.

## Search

In order to bypass the visual search input and directly input a query to view its results, the following path is used:

- /whitelab/search/results,

in combination with the following parameters:

- **query**: Your query formatted in Corpus Query Language.
- **within**: Optional. String value indicating to limit the query to matches within a 'document' (default), 'paragraph' or 'sentence'.
- **from**: Required to enable query editing. Integer value representing the original input screen (1=simple, 2=extended, 3=advanced, 4=expert). Defaults to 'expert'. Queries can be edited in their original input screen or any screen with a higher identifier.
- **number**: Optional. Integer value representing the number of results to show per page (default: 50).
- **first**: Optional. Integer value representing the index of the first result to include in the list (default: 0).
- **view**: Optional. Integer value representing the type of results to display (1=hits, 2=documents, 8=grouped hits, 16=grouped documents).
- **group**: Optional. Can only be used in combination with 'view=8' or 'view=16'. The following values can be used as input:
  - hit:word *
  - wordleft:word *
  - wordright:word *
  - hit:lemma *
  - wordleft:lemma *
  - wordright:lemma *
  - hit:pos *
  - wordleft:pos *
  - wordright:pos *
  - All metadata fields
  - * (only available when view=8)
- metadata: Metadata filters are optional. Each field may be used multiple times and accepts literal values only. Prefix a value with '-' to exclude it (for example: CollectionName=-Newspapers). Values consisting of multiple tokens should be surrounded with quotes (CollectionName="Discussion lists").
