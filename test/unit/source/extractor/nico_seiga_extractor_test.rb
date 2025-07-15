require "test_helper"

module Source::Tests::Extractor
  class NicoSeigaExtractorTest < ActiveSupport::TestCase
    setup do
      skip "NicoSeiga credentials not configured" unless Source::Extractor::NicoSeiga.enabled?
    end

    context "A nicoseiga post url" do
      tags = [
        ["アニメ", "https://seiga.nicovideo.jp/tag/アニメ"],
        ["コジコジ", "https://seiga.nicovideo.jp/tag/コジコジ"],
        ["さくらももこ", "https://seiga.nicovideo.jp/tag/さくらももこ"],
        ["ドット絵", "https://seiga.nicovideo.jp/tag/ドット絵"],
        ["ニコニコ大百科", "https://seiga.nicovideo.jp/tag/ニコニコ大百科"],
        ["お絵カキコ", "https://seiga.nicovideo.jp/tag/お絵カキコ"],
      ]
      strategy_should_work(
        "http://seiga.nicovideo.jp/seiga/im4937663",
        image_urls: [%r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/4937663}],
        media_files: [{ file_size: 2_032 }],
        page_url: "https://seiga.nicovideo.jp/seiga/im4937663",
        tags: tags,
        artist_name: "osamari",
        other_names: ["osamari"],
        tag_name: "nicoseiga_7017777",
        profile_url: "https://seiga.nicovideo.jp/user/illust/7017777",
        artist_commentary_title: "コジコジ",
        artist_commentary_desc: "コジコジのドット絵\nこんなかわいらしい容姿で毒を吐くコジコジが堪らん（切実）",
      )
    end

    context "A nicoseiga image url" do
      tags = [
        ["アニメ", "https://seiga.nicovideo.jp/tag/アニメ"],
        ["コジコジ", "https://seiga.nicovideo.jp/tag/コジコジ"],
        ["さくらももこ", "https://seiga.nicovideo.jp/tag/さくらももこ"],
        ["ドット絵", "https://seiga.nicovideo.jp/tag/ドット絵"],
        ["ニコニコ大百科", "https://seiga.nicovideo.jp/tag/ニコニコ大百科"],
        ["お絵カキコ", "https://seiga.nicovideo.jp/tag/お絵カキコ"],
      ]
      strategy_should_work(
        "http://lohas.nicoseiga.jp/o/910aecf08e542285862954017f8a33a8c32a8aec/1433298801/4937663",
        image_urls: [%r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/4937663}],
        media_files: [{ file_size: 2_032 }],
        page_url: "https://seiga.nicovideo.jp/seiga/im4937663",
        tags: tags,
        artist_name: "osamari",
        other_names: ["osamari"],
        tag_name: "nicoseiga_7017777",
        profile_url: "https://seiga.nicovideo.jp/user/illust/7017777",
        artist_commentary_title: "コジコジ",
        artist_commentary_desc: "コジコジのドット絵\nこんなかわいらしい容姿で毒を吐くコジコジが堪らん（切実）",
      )
    end

    context "A nicoseiga manga url" do
      image_urls = [
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/10315315},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/10315318},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/10315319},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/10315320},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/10315321},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/10315322},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/10315323},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/10315324},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/10315316},
      ]

      strategy_should_work(
        "https://seiga.nicovideo.jp/watch/mg470189?track=ct_episode",
        image_urls: image_urls,
        page_url: "https://manga.nicovideo.jp/watch/mg470189",
        artist_name: "風呂",
        profile_url: "https://seiga.nicovideo.jp/user/illust/20797022",
        artist_commentary_title: "ハコ女子 1ハコ目",
        artist_commentary_desc: "同じクラスの箱田さんはいつもハコを被っている。しかしてその素顔は…？　twitter(@hakojoshi1)にてだいたい毎日更新中。こっちだともうちょっと先まで読めるよ。",
      )
    end

    context "A nicoseiga manga url with deliver.cdn.nicomanga.jp images" do
      strategy_should_work(
        "https://seiga.nicovideo.jp/watch/mg658198",
        image_urls: %w[
          https://deliver.cdn.nicomanga.jp/thumb/12773050p?1655391688
          https://deliver.cdn.nicomanga.jp/thumb/12773051p?1655391688
          https://deliver.cdn.nicomanga.jp/thumb/12773052p?1655391688
          https://deliver.cdn.nicomanga.jp/thumb/12773053p?1655391688
          https://deliver.cdn.nicomanga.jp/thumb/12773054p?1655391688
          https://deliver.cdn.nicomanga.jp/thumb/12773055p?1655391688
          https://deliver.cdn.nicomanga.jp/thumb/12773056p?1655391688
        ],
        page_url: "https://manga.nicovideo.jp/watch/mg658198",
        artist_name: "あろめみ",
        profile_url: "https://seiga.nicovideo.jp/user/illust/123720050",
        tags: %w[DIY 日常],
        artist_commentary_title: "工作少女 Do It Yourself !!",
        artist_commentary_desc: "作業中のひとにいきなり話しかけるのはやめましょう",
      )
    end

    context "A nicoseiga manga url (2)" do
      strategy_should_work(
        "https://seiga.nicovideo.jp/watch/mg485611",
        image_urls: %w[
          https://deliver.cdn.nicomanga.jp/thumb/10543313p?1592370039
          https://deliver.cdn.nicomanga.jp/thumb/10543311p?1592262182
          https://deliver.cdn.nicomanga.jp/thumb/10543312p?1592262182
          https://deliver.cdn.nicomanga.jp/thumb/10543314p?1610453519
        ],
        media_files: [
          { file_size: 223_881 },
          { file_size: 208_968 },
          { file_size: 218_180 },
          { file_size: 113_071 },
        ],
        page_url: "https://manga.nicovideo.jp/watch/mg485611",
        profile_urls: %w[https://seiga.nicovideo.jp/user/illust/1116797],
        display_name: "まいまい",
        username: nil,
        tags: [
          ["ドラゴンクエスト", "https://seiga.nicovideo.jp/manga/tag/ドラゴンクエスト"],
          ["4コマ", "https://seiga.nicovideo.jp/manga/tag/4コマ"],
          ["ムーンブルクの王女", "https://seiga.nicovideo.jp/manga/tag/ムーンブルクの王女"],
          ["着替え中", "https://seiga.nicovideo.jp/manga/tag/着替え中"],
          ["マジックミラー", "https://seiga.nicovideo.jp/manga/tag/マジックミラー"],
        ],
        dtext_artist_commentary_title: "勇者さまが死んだので帰ります！ No.291 カミカゼアタック",
        dtext_artist_commentary_desc: <<~EOS.chomp,
          アソビ大全を買おうかどうしようか悩み中

          ※CG集で応援して頂けると、作者のやる気が上がります
          https://www.dlsite.com/home/circle/profile/=/maker_id/RG44783.html

          ※過去ログアーカイブはこちら↓
          https://manga.nicovideo.jp/comic/69386

          ※Ci-enも、よかったらフォローしてみてね
          https://ci-en.net/creator/28085
        EOS
      )
    end

    context "A https://lohas.nicoseiga.jp/thumb/${id}i url" do
      strategy_should_work(
        "https://lohas.nicoseiga.jp/thumb/6844226i",
        image_urls: [%r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/6844226}],
        page_url: "https://seiga.nicovideo.jp/seiga/im6844226",
      )
    end

    context "An image/source/123 url with referrer" do
      strategy_should_work(
        "https://seiga.nicovideo.jp/image/source/9146749",
        referer: "https://seiga.nicovideo.jp/watch/mg389884",
        image_urls: [%r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/9146749}],
        page_url: "https://manga.nicovideo.jp/watch/mg389884",
      )
    end

    context "A drm.cdn.nicomanga.jp image url" do
      strategy_should_work(
        "https://drm.cdn.nicomanga.jp/image/d4a2faa68ec34f95497db6601a4323fde2ccd451_9537/8017978p?1570012695",
        image_urls: [%r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017978}],
      )
    end

    context "A nico.ms illust url" do
      strategy_should_work(
        "https://nico.ms/im10922621",
        image_urls: [%r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/10922621}],
        page_url: "https://seiga.nicovideo.jp/seiga/im10922621",
        profile_url: "https://seiga.nicovideo.jp/user/illust/2258804",
      )
    end

    context "A nico.ms manga url from an anonymous user" do
      image_urls = [
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017978},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017979},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017980},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017981},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017982},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017983},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017984},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017985},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017986},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017987},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017988},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017989},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017990},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017991},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017992},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017993},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017994},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017995},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/8017996},
      ]

      strategy_should_work(
        "https://nico.ms/mg310193",
        image_urls: image_urls,
        artist_name: nil,
        profile_url: nil,
        artist_commentary_title: "ライブダンジョン！ 第1話前半",
      )
    end

    context "An anonymous illust" do
      strategy_should_work(
        "https://seiga.nicovideo.jp/seiga/im520647",
        image_urls: [%r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/520647}],
        artist_name: nil,
        profile_url: nil,
      )
    end

    context "A nicoseiga video" do
      strategy_should_work(
        "https://www.nicovideo.jp/watch/sm36465441",
      )
    end

    context "An oekaki direct url" do
      strategy_should_work(
        "https://dic.nicovideo.jp/oekaki/52833.png",
        image_urls: ["https://dic.nicovideo.jp/oekaki/52833.png"],
      )
    end

    context "A nicoseiga manga page with a single tag (source of XML misparsing)" do
      image_urls = [
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/7891076},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/7891080},
        %r{https://lohas\.nicoseiga\.jp/priv/\h+/\d+/7891081},
      ]
      strategy_should_work(
        "https://seiga.nicovideo.jp/watch/mg302561",
        image_urls: image_urls,
        page_url: "https://manga.nicovideo.jp/watch/mg302561",
        tags: [["ロリ", "https://seiga.nicovideo.jp/manga/tag/ロリ"]],
        artist_name: "とろてい",
        other_names: ["とろてい"],
        tag_name: "nicoseiga_1848060",
      )
    end

    context "A commentary with spoiler tags" do
      strategy_should_work(
        "https://seiga.nicovideo.jp/seiga/im8992650",
        image_urls: [%r{https://lohas.nicoseiga.jp/priv/\h+/\d+/8992650}],
        media_files: [{ file_size: 404_811 }],
        page_url: "https://seiga.nicovideo.jp/seiga/im8992650",
        profile_url: "https://seiga.nicovideo.jp/user/illust/11890767",
        profile_urls: %w[https://seiga.nicovideo.jp/user/illust/11890767],
        artist_name: "歯に挟まった昆布",
        other_names: ["歯に挟まった昆布"],
        tag_name: "nicoseiga_11890767",
        tags: [
          ["キャラクター", "https://seiga.nicovideo.jp/tag/キャラクター"],
          ["クッキー☆", "https://seiga.nicovideo.jp/tag/クッキー☆"],
          ["HZN", "https://seiga.nicovideo.jp/tag/HZN"],
          ["蓮奈理緒", "https://seiga.nicovideo.jp/tag/蓮奈理緒"],
          ["ダクッソー☆", "https://seiga.nicovideo.jp/tag/ダクッソー☆"],
          ["クッキー☆投稿者", "https://seiga.nicovideo.jp/tag/クッキー☆投稿者"],
          ["強キャラ", "https://seiga.nicovideo.jp/tag/強キャラ"],
          ["なにこれやばそう", "https://seiga.nicovideo.jp/tag/なにこれやばそう"],
          ["禍々しい", "https://seiga.nicovideo.jp/tag/禍々しい"],
        ],
        dtext_artist_commentary_title: "HZNN",
        dtext_artist_commentary_desc: <<~EOS.chomp,
          SLVN大好き。ホントニアコガレテル。

          [spoiler]
          「魔理沙とアリスのクッキーKiss」

          企画者HZNの企画した東方合同動画企画
          苦行を称する東方ボイスドラマ
          遥か昔、東方界隈のはずれ
          その偏境に消えぬボイスドラマの火を見出したとき
          若き健常者HZNの心にも
          消えぬ野心が灯ったのだろう

          戦技は「義務教育」
          クッキー☆を終わるまで視聴させる技
          27分にわたる苦行からのエンディングで視聴者はぬわ疲に包まれる
          [/spoiler]
        EOS
      )
    end
  end
end
