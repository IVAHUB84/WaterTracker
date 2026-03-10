// SettingsView.mc — экран настроек
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// =============================================================================
// Экран настроек

class SettingsView extends WatchUi.View {

    private static const ITEM_GOAL     as Number = 0;
    private static const ITEM_INTERVAL as Number = 1;
    private static const ITEM_UNITS    as Number = 2;
    private static const ITEM_COUNT    as Number = 3;

    // Допустимые значения целей (мл)
    private static const GOALS as Array<Number> =
        [1000, 1500, 2000, 2500, 3000, 3500, 4000, 5000, 6000, 7000, 8000, 9000, 10000];

    // Интервалы напоминаний (мин); 0 = выкл
    private static const INTERVALS as Array<Number> = [0, 30, 60, 90, 120];

    private var _cursor   as Number;
    private var _goalIdx  as Number;
    private var _intrIdx  as Number;
    private var _unitsIdx as Number;

    function initialize() {
        View.initialize();
        _cursor   = ITEM_GOAL;
        _goalIdx  = _findIdx(GOALS,     DataStore.getGoal());
        _intrIdx  = _findIdx(INTERVALS, DataStore.getInterval());
        _unitsIdx = DataStore.getUnits();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Заголовок
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, h * 10 / 100,
            Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.TitleSettings) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Разделитель под заголовком
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(16, h * 18 / 100, w - 16, h * 18 / 100);

        // Пункты
        var itemH  = h * 25 / 100;
        var startY = h * 20 / 100;

        for (var i = 0; i < ITEM_COUNT; i++) {
            _drawItem(dc, w, startY + i * itemH, itemH, i);
        }

        // Подсказка: SELECT = изменить
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, h * 96 / 100,
            Graphics.FONT_XTINY,
            "SELECT = change",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // Нарисовать один пункт настроек
    private function _drawItem(
        dc     as Graphics.Dc,
        w      as Number,
        y      as Number,
        h      as Number,
        idx    as Number
    ) as Void {
        var isActive = (idx == _cursor);

        // Фон активного пункта
        if (isActive) {
            dc.setColor(0x003366, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(8, y + 2, w - 16, h - 4, 6);
        }

        // Название — слева, маленький серый
        dc.setColor(
            isActive ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY,
            Graphics.COLOR_TRANSPARENT
        );
        dc.drawText(
            14, y + h * 30 / 100,
            Graphics.FONT_XTINY,
            _itemName(idx),
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Значение — справа, белый/жёлтый, FONT_TINY
        dc.setColor(
            isActive ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );
        dc.drawText(
            w - 14, y + h * 68 / 100,
            Graphics.FONT_TINY,
            _itemValue(idx),
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // Название пункта
    private function _itemName(idx as Number) as String {
        if (idx == ITEM_GOAL)     { return WatchUi.loadResource(Rez.Strings.SettingGoal)     as String; }
        if (idx == ITEM_INTERVAL) { return WatchUi.loadResource(Rez.Strings.SettingInterval) as String; }
                                    return WatchUi.loadResource(Rez.Strings.SettingUnits)    as String;
    }

    // Текущее значение пункта
    private function _itemValue(idx as Number) as String {
        if (idx == ITEM_GOAL) {
            var ml = GOALS[_goalIdx];
            if (_unitsIdx == 0) {
                return ml.toString() + " ml";
            }
            return (ml.toFloat() / 29.5735f).format("%.0f") + " oz";
        }
        if (idx == ITEM_INTERVAL) {
            var min = INTERVALS[_intrIdx];
            if (min == 0) { return WatchUi.loadResource(Rez.Strings.IntervalOff) as String; }
            return min.toString() + " min";
        }
        // ITEM_UNITS
        return (_unitsIdx == 0) ? "ml" : "oz";
    }

    // -------------------------------------------------------------------------
    // Методы для делегата

    function cursorNext() as Void {
        _cursor = (_cursor + 1) % ITEM_COUNT;
        WatchUi.requestUpdate();
    }

    function cursorPrev() as Void {
        _cursor = (_cursor + ITEM_COUNT - 1) % ITEM_COUNT;
        WatchUi.requestUpdate();
    }

    // direction: +1 вперёд, -1 назад по списку значений
    function changeValue(direction as Number) as Void {
        if (_cursor == ITEM_GOAL) {
            _goalIdx = _wrap(_goalIdx + direction, GOALS.size());
            DataStore.setGoal(GOALS[_goalIdx]);

        } else if (_cursor == ITEM_INTERVAL) {
            _intrIdx = _wrap(_intrIdx + direction, INTERVALS.size());
            DataStore.setInterval(INTERVALS[_intrIdx]);
            // Обновить расписание напоминаний немедленно
            WaterTrackerApp.scheduleReminder();

        } else if (_cursor == ITEM_UNITS) {
            _unitsIdx = _wrap(_unitsIdx + direction, 2);
            DataStore.setUnits(_unitsIdx);
        }
        WatchUi.requestUpdate();
    }

    // -------------------------------------------------------------------------
    // Приватные утилиты

    private function _findIdx(arr as Array<Number>, value as Number) as Number {
        for (var i = 0; i < arr.size(); i++) {
            if (arr[i] == value) { return i; }
        }
        return 0;
    }

    private function _wrap(idx as Number, size as Number) as Number {
        return ((idx % size) + size) % size;
    }
}

// =============================================================================
// Делегат настроек

class SettingsDelegate extends WatchUi.BehaviorDelegate {

    private var _view as SettingsView;

    function initialize(view as SettingsView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // DOWN — следующий пункт
    function onNextPage() as Boolean {
        _view.cursorNext();
        return true;
    }

    // UP — предыдущий пункт
    function onPreviousPage() as Boolean {
        _view.cursorPrev();
        return true;
    }

    // SELECT — изменить значение вперёд
    function onSelect() as Boolean {
        _view.changeValue(1);
        return true;
    }

    // BACK — выйти из настроек (данные уже сохранены в DataStore)
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
