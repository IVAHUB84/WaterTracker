// SettingsView.mc — экран настроек
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
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

    // Параметры пунктов (для tap-детектора)
    private var _itemH  as Number = 0;
    private var _startY as Number = 0;

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

        _itemH  = h * 26 / 100;
        _startY = h * 20 / 100;

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
        for (var i = 0; i < ITEM_COUNT; i++) {
            _drawItem(dc, w, _startY + i * _itemH, _itemH, i);
        }
    }

    // Нарисовать один пункт настроек
    private function _drawItem(
        dc  as Graphics.Dc,
        w   as Number,
        y   as Number,
        h   as Number,
        idx as Number
    ) as Void {
        var isActive = (idx == _cursor);
        var centerY  = y + h / 2;

        // Фон активного пункта — ярко-синий
        if (isActive) {
            dc.setColor(0x0055FF, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(8, y + 2, w - 16, h - 4, 8);
        }

        // Название — слева, FONT_TINY, белый
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            14, centerY,
            Graphics.FONT_TINY,
            _itemName(idx),
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Значение — справа, FONT_SMALL, белый
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w - 14, centerY,
            Graphics.FONT_SMALL,
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
            WaterTrackerApp.scheduleReminder();

        } else if (_cursor == ITEM_UNITS) {
            _unitsIdx = _wrap(_unitsIdx + direction, 2);
            DataStore.setUnits(_unitsIdx);
        }
        WatchUi.requestUpdate();
    }

    // Возвращает индекс пункта по Y-координате тапа; -1 если мимо
    function getItemAtY(tapY as Number) as Number {
        for (var i = 0; i < ITEM_COUNT; i++) {
            var itemY = _startY + i * _itemH;
            if (tapY >= itemY && tapY <= itemY + _itemH) {
                return i;
            }
        }
        return -1;
    }

    function setCursor(idx as Number) as Void {
        _cursor = idx;
        WatchUi.requestUpdate();
    }

    function getCursor() as Number {
        return _cursor;
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

    // TAP — выбрать пункт или изменить значение активного
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        var coords = evt.getCoordinates();
        var idx = _view.getItemAtY(coords[1]);
        if (idx >= 0) {
            if (idx == _view.getCursor()) {
                _view.changeValue(1);
            } else {
                _view.setCursor(idx);
            }
        }
        return true;
    }

    // SWIPE UP — следующий пункт
    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        var dir = evt.getDirection();
        if (dir == WatchUi.SWIPE_UP) {
            _view.cursorNext();
        } else if (dir == WatchUi.SWIPE_DOWN) {
            _view.cursorPrev();
        }
        return true;
    }

    // BACK — выйти из настроек (данные уже сохранены в DataStore)
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
