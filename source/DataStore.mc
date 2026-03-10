// DataStore.mc — хранение и управление данными
import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;

class DataStore {

    // Ключи хранилища
    private static const KEY_AMOUNT    = "amount";
    private static const KEY_DATE      = "date";
    private static const KEY_LAST_TIME = "lastTime";
    private static const KEY_GOAL      = "goal";
    private static const KEY_INTERVAL  = "interval";
    private static const KEY_UNITS     = "units";

    // Значения по умолчанию
    private static const DEFAULT_GOAL     = 2000; // мл
    private static const DEFAULT_INTERVAL = 60;   // минут
    private static const DEFAULT_UNITS    = 0;    // 0 = мл, 1 = oz

    // Загрузить текущий объём (с автосбросом при новом дне)
    static function getAmount() as Number {
        checkAndResetIfNewDay();
        var value = Application.Storage.getValue(KEY_AMOUNT);
        return (value != null) ? value as Number : 0;
    }

    // Добавить объём
    static function addAmount(ml as Number) as Number {
        var current = getAmount();
        var newAmount = current + ml;
        Application.Storage.setValue(KEY_AMOUNT, newAmount);
        Application.Storage.setValue(KEY_LAST_TIME, Time.now().value());
        return newAmount;
    }

    // Сбросить счётчик вручную
    static function reset() as Void {
        Application.Storage.setValue(KEY_AMOUNT, 0);
        Application.Storage.setValue(KEY_LAST_TIME, null);
        Application.Storage.setValue(KEY_DATE, _todayString());
    }

    // Дневная цель (мл)
    static function getGoal() as Number {
        var value = Application.Storage.getValue(KEY_GOAL);
        return (value != null) ? value as Number : DEFAULT_GOAL;
    }

    static function setGoal(goal as Number) as Void {
        Application.Storage.setValue(KEY_GOAL, goal);
    }

    // Интервал напоминаний (минуты), 0 = выключено
    static function getInterval() as Number {
        var value = Application.Storage.getValue(KEY_INTERVAL);
        return (value != null) ? value as Number : DEFAULT_INTERVAL;
    }

    static function setInterval(minutes as Number) as Void {
        Application.Storage.setValue(KEY_INTERVAL, minutes);
    }

    // Единицы измерения: 0 = мл, 1 = oz
    static function getUnits() as Number {
        var value = Application.Storage.getValue(KEY_UNITS);
        return (value != null) ? value as Number : DEFAULT_UNITS;
    }

    static function setUnits(units as Number) as Void {
        Application.Storage.setValue(KEY_UNITS, units);
    }

    // Время последнего приёма (Unix timestamp или null)
    static function getLastTime() as Number or Null {
        return Application.Storage.getValue(KEY_LAST_TIME);
    }

    // Процент выполнения цели
    static function getPercent() as Number {
        var goal = getGoal();
        if (goal <= 0) { return 0; }
        var pct = (getAmount() * 100) / goal;
        return pct > 100 ? 100 : pct;
    }

    // Цель достигнута?
    static function isGoalReached() as Boolean {
        return getAmount() >= getGoal();
    }

    // --- Приватные методы ---

    // Автосброс при смене дня
    private static function checkAndResetIfNewDay() as Void {
        var savedDate = Application.Storage.getValue(KEY_DATE);
        var today = _todayString();
        if (savedDate == null || !savedDate.equals(today)) {
            Application.Storage.setValue(KEY_AMOUNT, 0);
            Application.Storage.setValue(KEY_LAST_TIME, null);
            Application.Storage.setValue(KEY_DATE, today);
        }
    }

    // Строка текущей даты "YYYY-MM-DD"
    private static function _todayString() as String {
        var now = Time.now();
        var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        return info.year.toString() + "-" +
               info.month.toString() + "-" +
               info.day.toString();
    }
}
