# -*- encoding: utf-8 -*-
=begin
	�����A���g���[�Y�̎����\��y�[�W���X�N���C�s���O���CGoogle Calendar�p��CSV�t�@�C���ɏo�͂���
	�Q�lURL: http://www.engineyard.co.jp/blog/2012/getting-started-with-nokogiri/
=end
require "date"
require "csv"
require "nokogiri"
require "open-uri"

class GetAntlersGames
	# �X�N���C�s���O����URL
	URL = "http://www.so-net.ne.jp/antlers/games/"

	# �R���X�g���N�^
	def initialize(leagueNum = 34, cupNum = 7)
		# ���[�O��̎�����
		@leagueNum = leagueNum

		# ���[�O��e�X�e�[�W�̎�����
		@stageNum = @leagueNum / 2

		# ACL/�i�r�X�R�O���[�v�X�e�[�W�̎�����
		@cupNum = cupNum
	end

	# Nokogiri��html���擾����
	def get_html
		charset = nil
		html = open(URL) do |f|
			charset = f.charset
			f.read
		end
		@doc = Nokogiri::HTML.parse(html, nil, charset)
	end

	# xpath�Ŏ擾����html���p�[�X����
	def scraping
		@data = []  # �����\�肪�i�[�����2�����z��
		tmp   = []  # ���[�N1�����z��
		row   = 1   # �J�E���^
		gameNum = 1 # ���ݓǂݍ���ł��鎎���̒ʂ��ԍ�

		@doc.xpath('//div[@class = "result_table"]//td').each do |node|
			# �����񉻂��ċ󔒂���������
			str = node.text.strip

			# �e�����̐߁C�����C���ԂȂǂ�z��Ƃ���tmp�Ɋi�[����
			if row < 7
				tmp << str
				row += 1
			# tmp(�e�����̏��)��data�ɃR�s�[����
			else
				@data << tmp

				# tmp������������
				tmp = []

				row = 1
				gameNum += 1
				next
			end
		end
	end

	# Google Calendar�`���ɕϊ�����
	def convert_gcal
		@result = []  # gcal�ϊ���

		@data.each_with_index do |line, row|
			# �����̐���
			matchNum = line[0].insert(0, "\#")
			matchNum.delete!("��")
			matchNum.delete!("��")
			matchNum.delete!("��")

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

			# ���t�̐ݒ�
			dt = Date.today
			day = line[1].slice(0, line[1].index("("))
			day.insert(0, dt.strftime("%Y/"))

			# �J�n�E�I�����Ԃ̐ݒ�
			if line[2] == "����"
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

			# �X�^�W�A�����̐ݒ�
			stadium = line[3]

			@result << [title, day, sTime, day, eTime, allDayFlag, stadium]
		end
	end

	# CSV�t�@�C���ɏo�͂���
	def output_csv(file_name)
		CSV.open(file_name, "w", :encoding => "SJIS") do |csv|
			csv << ["����", "�J�n��" , "�J�n����", "�I����", "�I������", "�I���C�x���g", "�ꏊ"]

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
antlers.output_csv("��������.csv")
