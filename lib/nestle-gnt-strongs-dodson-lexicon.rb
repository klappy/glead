# Parse Nestle Greek New Testament
#   https://raw.githubusercontent.com/biblicalhumanities/Nestle1904/master/Nestle1904.csv
# Parse Dodson Greek Lexicon
#   https://github.com/biblicalhumanities/Dodson-Greek-Lexicon/blob/master/dodson.csv

class GreekNewTestamentLexicon
  require 'csv'
  require 'pry'
  require 'json'

  attr :books, :gnt_source_uri, :lexicon, :lexicon_source_uri, :words

  def initialize(params={})
    @gnt_source_uri = params[:gnt_source] || "../sources/nestle1904/nestle1904-luke-eph.csv"
    @books = {}
    @lexicon_source_uri = params[:lexicon_source] || "../sources/dodson-greek-lexicon/dodson-english.csv"
    @lexicon = {}
    @words = {}

    lexicon_parse(lexicon_source_uri)
    gnt_parse(gnt_source_uri)
  end

  def lexicon_parse(url)
    CSV.new(open(url), col_sep: "\t", headers: :first_row).each do |record|
      strongs = record[0].gsub(/^0+/,'')
      lexicon[strongs] = { brief: record[3], long: record[4] }
    end
  end

  def gnt_parse(url)
    CSV.new(open(url), col_sep: "\t").each do |record|
      ref = reference(record[0])
      books[ref[:book]] ||= {}
      books[ref[:book]][ref[:chapter]] ||= {}
      books[ref[:book]][ref[:chapter]][ref[:verse]] ||= []

      strongs = record[4]
      strongs.split('&').each do |_strongs|
        if lexicon[_strongs]
          word = {
            greek: record[1],
            strongs: _strongs,
            morphology: record[2],
            brief: lexicon[_strongs][:brief],
            long: lexicon[_strongs][:long],
            count: 0
          }
          books[ref[:book]][ref[:chapter]][ref[:verse]] << word unless word.empty?
          words[_strongs] ||= word
          words[_strongs][:count] += 1
        end
      end
    end
  end

  def reference(ref, reference=ref.dup, _reference={}) # reference("Matt 13:55") #=> {book: "Matt", chapter: '13', verse: '55'}
    book_ids = %w(nil Matt Mark Luke John Acts Rom 1Co 2Co Gal Eph Phi Col 1Th 2Th 1Ti 2Ti Tit Phm Heb Jam 1Pe 2Pe 1Jo 2Jo 3Jo Jud Rev)
    book_names = %w(nil Matthew Mark Luke John Acts Romans 1Corinthians 2Corinthians Galatians Ephesians Philippians Colossians 1Thessalonians 2Thessalonians 1Timothy 2Timothy Titus Philemon Hebrews James 1Peter 2Peter 1John 2John 3John Jude Revelation)
    _book = book_names[book_ids.index(reference.gsub(/\s+\d+:\d+$/,'').strip)]

    _reference[:book] = _book
    _reference[:chapter] = reference[/\d+:\d+$/].gsub(/:\d+/,'').strip
    _reference[:verse] = reference[/\d+:\d+$/].gsub(/\d+:/,'').strip
    return _reference
  end

  def lexicon_json
    JSON.pretty_generate(lexicon)
  end

  def gnt_json
    JSON.pretty_generate(books)
  end

  def words_sorted
    words_count = words.map{|_strongs_number, word_data| word_data}.compact
    words_count.sort_by!{|word| word[:count]}.reverse!
    words_count.reject!{|word| word[:count] == 0}
    words_count
  end

  def words_sorted_json
    JSON.pretty_generate(words_sorted)
  end

  def words_sorted_csv
    csv_string = CSV.generate do |csv|
      csv << ["strongs", "greek", "count", "brief", "long"]
      words_sorted.map do |word|
        csv << [ word[:strongs], word[:greek], word[:count], word[:brief], word[:long] ]
      end
    end
    csv_string
  end

  def gnt_html
    html = "<!DOCTYPE html><html><head><meta charset='utf-8'></head><html><body>\n"
    books.each do |book, book_data|
      html << "<h2>#{book}</h2>\n"
      html << "<div class='book'>\n"
      book_data.each do |chapter, chapter_data|
        html << "<h3>Chapter #{chapter}</h3>\n"
        html << "<div class='chapter'>\n"
        chapter_data.each do |verse, verse_data|
          html << "<p>#{verse} "
          verse_data.each do |word_data|
            html << "<span title='Greek: #{word_data[:greek]}, Morphology: #{word_data[:morphology]}, Strongs: #{word_data[:strongs]}, Definition: #{word_data[:long]}'>#{word_data[:brief] || '?'}</span> | "
          end
          html << "</p>\n"
        end
        html << "</div>\n"
      end
      html << "</div>\n"
    end
    html << "</body></html>"
  end
end

gnt = GreekNewTestamentLexicon.new()
puts gnt.gnt_json
