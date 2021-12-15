extends Resource
class_name Time

const MINUTES_TO_SECONDS = 60.0
const HOURS_TO_SECONDS = 60.0 * MINUTES_TO_SECONDS
const DAYS_TO_SECONDS = 24.0 * HOURS_TO_SECONDS
const WEEKS_TO_SECONDS = 7.0 * DAYS_TO_SECONDS
const MONTHS_TO_SECONDS = 4.0 * WEEKS_TO_SECONDS
const YEARS_TO_SECONDS = 12.0 * MONTHS_TO_SECONDS


export var year:int = 0
export(int, 0, 11) var month:int = 0
export(int, 0, 3) var week:int = 0
export(int, 0, 6) var day:int = 0
export(int, 0, 23) var hour:int = 0
export(int, 0, 59) var minute:int = 0
export(int, 0, 59) var second:int = 0
var subseconds:float = 0.0

func get_time() -> float:
	var minute_in_seconds:int = minute*MINUTES_TO_SECONDS
	var hour_in_seconds:int = hour*HOURS_TO_SECONDS
	var day_in_seconds:int = day*DAYS_TO_SECONDS
	var week_in_seconds:int = week*WEEKS_TO_SECONDS
	var month_in_seconds:int = month*MONTHS_TO_SECONDS
	var year_in_seconds:int = year*YEARS_TO_SECONDS
	return second + minute_in_seconds + hour_in_seconds + day_in_seconds + week_in_seconds + month_in_seconds + year_in_seconds + subseconds

func get_second() -> float:
	return second + subseconds

func get_minute() -> float:
	return minute + (get_second()/60.0)

func get_hour() -> float:
	return hour + (get_minute()/60.0)

func get_day() -> float:
	return day + (get_hour()/24.0)

func get_week() -> float:
	return week + (get_day()/7.0)

func get_month() -> float:
	return month + (get_week()/4.0)

func get_year() -> float:
	return year + (get_month()/12.0)

func get_minute_time() -> float:
	return get_time() / MINUTES_TO_SECONDS
func get_hour_time() -> float:
	return get_time() / HOURS_TO_SECONDS
func get_day_time() -> float:
	return get_time() / DAYS_TO_SECONDS
func get_week_time() -> float:
	return get_time() / WEEKS_TO_SECONDS
func get_month_time() -> float:
	return get_time() / MONTHS_TO_SECONDS
func get_year_time() -> float:
	return get_time() / YEARS_TO_SECONDS

func add_years(years:int):
	year += years

func add_months(months:int):
	month += months
	if month >= 12 or month < 0:
		var years:int = floor(month / 12.0)
		month -= years * 12
		add_years(years)

func add_weeks(weeks:int):
	week += weeks
	if week >= 4 or week < 0:
		var months:int = floor(week / 4.0)
		week -= months * 4
		add_months(months)

func add_days(days:int):
	day += days
	if day >= 7 or day < 0:
		var weeks:int = floor(day / 7.0)
		day -= week * 7
		add_weeks(weeks)

func add_hours(hours:int):
	hour += hours
	if hour >= 24 or hour < 0:
		var days:int = floor(hour / 24.0)
		hour -= days * 24
		add_days(days)

func add_minutes(minutes:int):
	minute += minutes
	if minute >= 60 or minute < 0:
		var hours:int = floor(minute / 60.0)
		minute -= hours * 60
		add_hours(hours)

func add_seconds(delta:float):
	subseconds += delta
	if subseconds >= 1.0 or subseconds < 0.0:
		var seconds:int = floor(subseconds)
		second += seconds
		subseconds -= seconds
	
	
	if second >= 60 or second < 0:
		var minutes:int = floor(second / 60.0)
		second -= minutes * 60
		add_minutes(minutes)

func set_time(time:float):
	year = 0
	month = 0
	week = 0
	day = 0
	hour = 0
	minute = 0
	second = 0
	subseconds = 0
	add_seconds(time)
	
func _init(time:float = 0):
	# only set the time if it's not 0 since 0 is the default
	if time:
		set_time(time)

func _to_string() -> String:
	return "%ss %dm %dh %dD %dW %dM %dY" % [second + subseconds, minute, hour, day, week, month, year]
