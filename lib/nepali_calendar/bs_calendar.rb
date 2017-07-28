module NepaliCalendar
  class BsCalendar < NepaliCalendar::Calendar
    YUNICODE = %w{nil २००० २००१ २००२ २००३ २००४ २००५ २००६ २००७ २००८ २००९ २०१० २०११ २०१२ २०१३ २०१४ २०१५ २०१६ २०१७ २०१८ २०१९ २०२० २०२१ २०२२ २०२३ २०२४ २०२५ २०२६ २०२७ २०२८ २०२९ २०३० २०३१ २०३२ २०३३ २०३४ २०३५ २०३६ २०३७ २०३८ २०३९ २०४० २०४१ २०४२ २०४३ २०४४ २०४५ २०४६ २०४७ २०४८ २०४९ २०५० २०५१ २०५२ २०५३ २०५४ २०५५ २०५६ २०५७ २०५८ २०५९ २०६० २०६१ २०६२ २०६३ २०६४ २०६५ २०६६ २०६७ २०६८ २०६९ २०७० २०७१ २०७२ २०७३ २०७४ २०७५ २०७६ २०७७ २०७८ २०७९ २०८० २०८१ २०८२ २०८३ २०८४ २०८५ २०८६ २०८७ २०८८ २०८९ २०९०}
    MONTHNAMES = %w{nil बैसाख जेष्ठ असार श्रावण भाद्र आश्विन कार्तिक मंसिर पुष माघ फाल्गुन चैत्र}
    DAYNAMES = %w{nil आइतबार सोमबार मंगलबार बुधबार बिहिबार शुक्रबार शनिवार}
    DAY = %w{nil १ २ ३ ४ ५ ६ ७ ८ ९ १० ११ १२ १३ १४ १५ १६ १७ १८ १९ २० २१ २२ २३ २४ २५ २६ २७ २८ २९ ३० ३१ ३२}

    class << self
      def ad_to_bs(year, month, day)
        fail 'Invalid AD date!' unless valid_date?(year, month, day)

        ref_day_eng = get_ref_day_eng
        date_ad = Date.parse("#{year}/#{month}/#{day}")
        return unless date_in_range?(date_ad, ref_day_eng)

        days = total_days(date_ad, ref_day_eng)
        get_bs_date(days, ref_date['ad_to_bs']['bs'])
      end

      def get_bs_date(days, ref_day_nep)
        wday = 7
        year, month, day = ref_day_nep.split('/').map(&:to_i)
        travel days, year: year, month: month, day: day, wday: wday
      end

      def today
        date = Date.today
        ad_to_bs(date.year, date.month, date.day)
      end
    end

    def beginning_of_week
      date = {year: year, month: month, day: day, wday: wday}
      days = (wday > 1) ? -(wday - 1) : 0
      NepaliCalendar::BsCalendar.travel days, date
    end

    def end_of_week
      date = {year: year, month: month, day: day, wday: wday}
      days = (wday < 7) ? (7 - wday) : 0
      NepaliCalendar::BsCalendar.travel days, date
    end

    def beginning_of_month
      date = {year: year, month: month, day: day, wday: wday}
      days = -(day - 1)
      NepaliCalendar::BsCalendar.travel days, date
    end

    def end_of_month
      date = {year: year, month: month, day: day, wday: wday}
      days = NepaliCalendar::BS[year][month] - day
      NepaliCalendar::BsCalendar.travel days, date
    end

    private

      def self.travel days, option = {}
        return if days.nil? && days.zero?

        if days < 0
          option = travel_backward(days, option)
        else
          option = travel_forward(days, option)
        end
        NepaliCalendar::BsCalendar.date_object(option)
      end

      def self.travel_forward days, option = {}
        year = option[:year]
        month = option[:month]
        day = option[:day]
        wday = option[:wday]

        while days != 0
          bs_month_days = NepaliCalendar::BS[year][month]
          day += 1
          wday += 1
          wday = 1 if wday > 7

          if day > bs_month_days
            month += 1
            day = 1
          end

          if month > 12
            year += 1
            month = 1
          end

          days -= 1
        end
        option = {year: year, month: month, day: day, wday: wday}
      end

      def self.travel_backward days, option = {}
        year = option[:year]
        month = option[:month]
        day = option[:day]
        wday = option[:wday]

        while days != 0
          day -= 1
          wday -= 1
          wday = 7 if wday < 1

          if day < 1
            month -= 1
            if month < 1
              year -= 1
              month = 12
            end
            day = NepaliCalendar::BS[year][month]
          end

          days += 1
        end
        option = {year: year, month: month, day: day, wday: wday}
      end

      def self.date_object date
        y_name = YUNICODE[date[:year]]
        month_name = MONTHNAMES[date[:month]]
        wday_name = DAYNAMES[date[:wday]]
        day_unicode = DAY[date[:day]]
        option = { year: date[:year], month: date[:month], day: date[:day],
          wday: date[:wday], y_name: y_name, month_name: month_name, wday_name: wday_name, day_unicode: day_unicode }
        new('', option)
      end

      def self.get_ref_day_eng
         Date.parse(ref_date['ad_to_bs']['ad'])
      end

      def start_date
        date = view_context.params.fetch(:start_date, '')
        date.blank? ? NepaliCalendar::BsCalendar.today : to_bs_date(date)
      end

      def to_bs_date(date)
        d = date.split('-').map(&:to_i)
        d = NepaliCalendar::AdCalendar.bs_to_ad(d[0], d[1], d[2])
        NepaliCalendar::BsCalendar.ad_to_bs(d.year, d.month, d.day)
      end

      def date_range
        [
          start_date.beginning_of_month.beginning_of_week,
          start_date.end_of_month.end_of_week
        ]
      end
  end
end
