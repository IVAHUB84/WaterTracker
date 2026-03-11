// DataStore.mc — хранение и управление данными
import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;

class DataStore {

    // Ключи хранилища
    private static const KEY_AMOUNT    as String = "amount";
    private static const KEY_DATE      as String = "date";
    private static const KEY_LAST_TIME as String = "lastTime";
    private static const KEY_GOAL      as String = "goal";
    private static const KEY_INTERVAL  as String = "interval";
    private static const KEY_UNITS     as String = "units";

    // Значения по умолчанию
    private static const DEFAULT_GOAL     as Number = 2000; // мл
    private static const DEFAULT_INTERVAL as Number = 60;   // минут (0 = выкл)
    private static const DEFAULT_UNITS    as Number = 0;    // 0 = мл, 1 = oz

    // -------------------------------------------------------------------------
    // Основные методы работы с объёмом

    // Текущий выпитый объём за день (с автосбросом)
    (:background)
    static function getAmount() as Number {
        _checkAndResetIfNewDay();
        var value = Application.Storage.getValue(KEY_AMOUNT);
        return (value instanceof Number) ? (value as Number) : 0;
    }

    // Добавить объём (может быть отрицательным); не уходит ниже 0
    static function addAmount(ml as Number) as Number {
        var current = getAmount();
        var newAmount = current + ml;
        if (newAmount < 0) { newAmount = 0; }
        Application.Storage.setValue(KEY_AMOUNT, newAmount);
        if (ml > 0) {
            Application.Storage.setValue(KEY_LAST_TIME, Time.now().value());
        }
        return newAmount;
    }

    // Сбросить счётчик вручную (например кнопкой)
    static function reset() as Void {
        Application.Storage.setValue(KEY_AMOUNT, 0);
        Application.Storage.deleteValue(KEY_LAST_TIME);
        Application.Storage.setValue(KEY_DATE, _todayString());
    }

    // -------------------------------------------------------------------------
    // Дневная цель

    (:background)
    static function getGoal() as Number {
        var value = Application.Storage.getValue(KEY_GOAL);
        return (value instanceof Number) ? (value as Number) : DEFAULT_GOAL;
    }

    static function setGoal(goal as Number) as Void {
        // Ограничиваем допустимый диапазон согласно ТЗ
        if (goal < 1000) { goal = 1000; }
        if (goal > 10000) { goal = 10000; }
        Application.Storage.setValue(KEY_GOAL, goal);
    }

    // -------------------------------------------------------------------------
    // Интервал напоминаний

    // Возвращает интервал в минутах; 0 = напоминания выключены
    (:background)
    static function getInterval() as Number {
        var value = Application.Storage.getValue(KEY_INTERVAL);
        return (value instanceof Number) ? (value as Number) : DEFAULT_INTERVAL;
    }

    static function setInterval(minutes as Number) as Void {
        Application.Storage.setValue(KEY_INTERVAL, minutes);
    }

    // -------------------------------------------------------------------------
    // Единицы измерения

    // 0 = мл, 1 = oz
    static function getUnits() as Number {
        var value = Application.Storage.getValue(KEY_UNITS);
        return (value instanceof Number) ? (value as Number) : DEFAULT_UNITS;
    }

    static function setUnits(units as Number) as Void {
        Application.Storage.setValue(KEY_UNITS, units);
    }

    // -------------------------------------------------------------------------
    // Производные значения

    // Unix-timestamp последнего приёма воды; null если не было сегодня
    static function getLastTime() as Number? {
        var value = Application.Storage.getValue(KEY_LAST_TIME);
        return (value instanceof Number) ? (value as Number) : null;
    }

    // Процент выполнения цели [0..100]
    static function getPercent() as Number {
        var goal = getGoal();
        if (goal <= 0) { return 0; }
        var amount = getAmount(); // один вызов, одна проверка даты
        var pct = (amount * 100) / goal;
        return (pct > 100) ? 100 : pct;
    }

    // Цель выполнена?
    (:background)
    static function isGoalReached() as Boolean {
        return getAmount() >= getGoal();
    }

    // -------------------------------------------------------------------------
    // Приватные методы

    // Автосброс при смене дня
    (:background)
    private static function _checkAndResetIfNewDay() as Void {
        var savedDate = Application.Storage.getValue(KEY_DATE);
        var today = _todayString();
        var isDifferentDay = !(savedDate instanceof String) ||
                             !(savedDate as String).equals(today);
        if (isDifferentDay) {
            Application.Storage.setValue(KEY_AMOUNT, 0);
            Application.Storage.deleteValue(KEY_LAST_TIME);
            Application.Storage.setValue(KEY_DATE, today);
        }
    }

    // Строка текущей даты "YYYY-M-D" (для сравнения, не для отображения)
    (:background)
    private static function _todayString() as String {
        var info = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return info.year.toString() + "-" +
               info.month.toString() + "-" +
               info.day.toString();
    }
}
