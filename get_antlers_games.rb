# -*- encoding: utf-8 -*-
=begin
	鹿島アントラーズの試合予定ページをスクレイピングし，Google Calendar用のCSVファイルに出力する
	参考URL: http://www.engineyard.co.jp/blog/2012/getting-started-with-nokogiri/
=end
require "date"
require "csv"
require "nokogiri"
require "open-uri"

class GetAntlersGames
	# スクレイピングするURL
	URL = "http://www.so-net.ne.jp/antlers/games/"

	# コンストラクタ
	def initialize(leagueNum = 34, cupNum = 7)
		# リーグ戦の試合数
		@leagueNum = leagueNum

		# リーグ戦各ステージの試合数
		@stageNum = @leagueNum / 2

		# ACL/ナビスコグループステージの試合数
		@cupNum = cupNum
	end

	# Nokogiriでhtmlを取得する
	def get_html
		charset = nil
		html = open(URL) do |f|
			charset = f.charset
			f.read
		end
		@doc = Nokogiri::HTML.parse(html, nil, charset)
	end

	# xpathで取得したhtmlをパースする
	def scraping
		@data = []  # 試合予定が格納される2次元配列
		tmp   = []  # ワーク1次元配列
		row   = 1   # カウンタ
		gameNum = 1 # 現在読み込んでいる試合の通し番号

		@doc.xpath('//div[@class = "result_table"]//td').each do |node|
			# 文字列化して空白を除去する
			str = node.text.strip

			# 各試合の節，日程，時間などを配列としてtmpに格納する
			if row < 7
				tmp << str
				row += 1
			# tmp(各試合の情報)をdataにコピーする
			else
				@data << tmp

				# tmpを初期化する
				tmp = []

				row = 1
				gameNum += 1
				next
			end
		end
	end

	# Google Calendar形式に変換する
	def convert_gcal
		@result = []  # gcal変換後

		@data.each_with_index do |line, row|
			# 件名の生成
			matchNum = line[0].insert(0, "\#")
			matchNum.delete!("第")
			matchNum.delete!("節")
			matchNum.delete!("戦")

			teamName = line[5]

			if row + 1 <= @stageNum
				title = "J1-1" + matchNum + " " + teamName
			elsif row + 1 <= @leagueNum
				title = "J1-2" + matchNum + " " + teamName
			elsif row + 1 <= @leagueNum + @cupNum
				title = "NC GL" + matchNum + " " + teamName
			else
				title = matchNum.delete!("\#") + " " + teamName
			end

			# 日付の設定
			dt = Date.today
			day = line[1].slice(0, line[1].index("("))
			day.insert(0, dt.strftime("%Y/"))

			# 開始・終了時間の設定
			if line[2] == "未定"
				sTime = ""
				eTime = ""
				allDayFlag = "TRUE"
			else
				sTime = line[2]

				time = line[2].split(":")
				hour = time[0].to_i + 2
				min  = time[1]
				time = hour.to_s + ":" + min

				eTime = time
				allDayFlag = ""
			end

			# スタジアム名の設定
			stadium = line[3]

			@result << [title, day, sTime, day, eTime, allDayFlag, stadium]
		end
	end

	# CSVファイルに出力する
	def output_csv(file_name)
		CSV.open(file_name, "w", :encoding => "SJIS") do |csv|
			csv << ["件名", "開始日" , "開始時刻", "終了日", "終了時刻", "終日イベント", "場所"]

			@result.each do |line|
				csv << line
			end
		end
	end
end

# ------------------- main -------------------
antlers = GetAntlersGames.new
antlers.get_html
antlers.scraping
antlers.convert_gcal
antlers.output_csv("鹿島日程.csv")
