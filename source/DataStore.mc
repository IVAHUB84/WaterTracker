// DataStore.mc — хранение и управление данными
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Time;
import Toybox.UserProfile;

// Module-level флаг: true если профиль пользователя неполный
var _profileIncomplete as Boolean = false;

class DataStore {

    // Ключи хранилища
    private static const KEY_AMOUNT      as String = "amount";
    private static const KEY_DATE        as String = "date";
    private static const KEY_LAST_TIME   as String = "lastTime";
    private static const KEY_GOAL        as String = "goal";
    private static const KEY_GOAL_MANUAL as String = "goalManual";
    private static const KEY_INTERVAL    as String = "interval";
    private static const KEY_UNITS       as String = "units";

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
            _checkVibration(current, newAmount);
        }
        return newAmount;
    }

    // Вибрация при достижении GOAL (1 раз) или REC (2 раза)
    private static function _checkVibration(oldAmt as Number, newAmt as Number) as Void {
        if (!(Toybox has :Attention) || !(Attention has :vibrate)) { return; }
        var goal = getGoal();
        var rec  = getRecommendedGoal();
        var crossedGoal = (oldAmt < goal && newAmt >= goal);
        var crossedRec  = (oldAmt < rec  && newAmt >= rec);
        if (crossedRec) {
            // Две вибрации (включая случай REC == GOAL)
            Attention.vibrate([
                new Attention.VibeProfile(75, 250),
                new Attention.VibeProfile(0,  150),
                new Attention.VibeProfile(75, 250)
            ]);
        } else if (crossedGoal) {
            // Одна вибрация
            Attention.vibrate([new Attention.VibeProfile(75, 400)]);
        }
    }

    // Сбросить счётчик вручную (например кнопкой)
    static function reset() as Void {
        Application.Storage.setValue(KEY_AMOUNT, 0);
        Application.Storage.deleteValue(KEY_LAST_TIME);
        Application.Storage.deleteValue(KEY_GOAL);
        Application.Storage.deleteValue(KEY_GOAL_MANUAL);
        Application.Storage.setValue(KEY_DATE, _todayString());
    }

    // -------------------------------------------------------------------------
    // Дневная цель

    (:background)
    static function getGoal() as Number {
        var manual = Application.Storage.getValue(KEY_GOAL_MANUAL);
        if (manual instanceof Boolean && (manual as Boolean)) {
            var value = Application.Storage.getValue(KEY_GOAL);
            return (value instanceof Number) ? (value as Number) : DEFAULT_GOAL;
        }
        return getBaseRecommendedGoal();
    }

    // manual=true  — пользователь сам выбрал значение (не сбрасывать до следующего дня)
    // manual=false — автоматическая установка (сбрасывается вместе с днём)
    static function setGoal(goal as Number, manual as Boolean) as Void {
        if (goal < 1000) { goal = 1000; }
        if (goal > 10000) { goal = 10000; }
        Application.Storage.setValue(KEY_GOAL, goal);
        Application.Storage.setValue(KEY_GOAL_MANUAL, manual);
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
    // Рекомендованная норма воды

    // Рассчитывает рекомендованную норму по весу, полу и активности.
    // Устанавливает module-level флаг _profileIncomplete если данных нет.
    static function getRecommendedGoal() as Number {
        _profileIncomplete = false;

        // Проверяем наличие UserProfile API
        if (!(Toybox has :UserProfile)) {
            _profileIncomplete = true;
            return 2000;
        }

        var profile = UserProfile.getProfile();
        if (profile == null) {
            _profileIncomplete = true;
            return 2000;
        }

        var weightG = profile.weight;
        var gender  = profile.gender;

        if (weightG == null || gender == null ||
            gender != UserProfile.GENDER_MALE && gender != UserProfile.GENDER_FEMALE) {
            _profileIncomplete = true;
            return 2000;
        }

        var weightKg    = (weightG as Number).toFloat() / 1000.0;
        var base        = (weightKg * 33.0).toNumber();
        var genderBonus = (gender == UserProfile.GENDER_MALE) ? 200 : 0;

        // Активные минуты → бонус к норме (~8ml/мин умеренной активности)
        var actBonus = 0;
        if (Toybox has :ActivityMonitor) {
            var info = ActivityMonitor.getInfo();
            if (info != null) {
                var am = info.activeMinutesDay;
                if (am != null) {
                    var mod = (am.moderate != null) ? (am.moderate as Number) : 0;
                    var vig = (am.vigorous != null) ? (am.vigorous as Number) : 0;
                    actBonus = (mod + vig * 2) * 8;
                }
            }
        }

        return base + genderBonus + actBonus;
    }

    // Базовая норма без учёта активности (вес × 33 + пол)
    static function getBaseRecommendedGoal() as Number {
        if (!(Toybox has :UserProfile)) { return 2000; }
        var profile = UserProfile.getProfile();
        if (profile == null) { return 2000; }
        var weightG = profile.weight;
        var gender  = profile.gender;
        if (weightG == null || gender == null ||
            gender != UserProfile.GENDER_MALE && gender != UserProfile.GENDER_FEMALE) { return 2000; }
        var weightKg    = (weightG as Number).toFloat() / 1000.0;
        var base        = (weightKg * 33.0).toNumber();
        var genderBonus = (gender == UserProfile.GENDER_MALE) ? 200 : 0;
        return base + genderBonus;
    }

    // Возвращает флаг неполноты профиля (обновляется при вызове getRecommendedGoal)
    static function isProfileIncomplete() as Boolean {
        return _profileIncomplete;
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
            Application.Storage.deleteValue(KEY_GOAL);
            Application.Storage.deleteValue(KEY_GOAL_MANUAL);
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
