// SettingsView.mc — экран настроек
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SettingsView extends WatchUi.View {

    // Пункты меню
    private static const ITEM_GOAL     = 0;
    private static const ITEM_INTERVAL = 1;
    private static const ITEM_UNITS    = 2;

    private static const ITEM_COUNT = 3;

    // Варианты целей (мл)
    private static const GOALS = [1000, 1500, 2000, 2500, 3000, 3500, 4000, 5000] as Array<Number>;

    // Варианты интервалов (минуты), 0 = выкл
    private static const INTERVALS = [0, 30, 60, 90, 120] as Array<Number>;

    private var _cursor   as Number = ITEM_GOAL;
    private var _goalIdx  as Number = 0;
    private var _intrIdx  as Number = 0;
    private var _unitsIdx as Number = 0;

    function initialize() {
        View.initialize();
        // Загрузить текущие значения
        _goalIdx  = _findIndex(GOALS,     DataStore.getGoal());
        _intrIdx  = _findIndex(INTERVALS, DataStore.getInterval());
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

        // Пункты настроек
        var items = [
            [WatchUi.loadResource(Rez.Strings.SettingGoal) as String,
             GOALS[_goalIdx].toString() + " ml"],
            [WatchUi.loadResource(Rez.Strings.SettingInterval) as String,
             _intervalLabel(INTERVALS[_intrIdx])],
            [WatchUi.loadResource(Rez.Strings.SettingUnits) as String,
             _unitsIdx == 0 ? "ml" : "oz"]
        ] as Array<Array<String>>;

        var itemH  = h * 22 / 100;
        var startY = h * 22 / 100;

        for (var i = 0; i < ITEM_COUNT; i++) {
            var isActive = (i == _cursor);
            var itemY    = startY + i * itemH;

            // Фон активного пункта
            if (isActive) {
                dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(10, itemY - 2, w - 20, itemH - 4, 6);
            }

            // Название пункта
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                15, itemY + itemH / 4,
                Graphics.FONT_TINY,
                items[i][0],
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
            );

            // Значение
            dc.setColor(isActive ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY,
                        Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                w - 15, itemY + itemH * 3 / 4,
                Graphics.FONT_SMALL,
                items[i][1],
                Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }

    // Курсор вниз
    function cursorNext() as Void {
        _cursor = (_cursor + 1) % ITEM_COUNT;
        WatchUi.requestUpdate();
    }

    // Курсор вверх
    function cursorPrev() as Void {
        _cursor = (_cursor + ITEM_COUNT - 1) % ITEM_COUNT;
        WatchUi.requestUpdate();
    }

    // Изменить значение активного пункта (вправо / увеличить)
    function changeValue(direction as Number) as Void {
        if (_cursor == ITEM_GOAL) {
            _goalIdx = _wrapIndex(_goalIdx + direction, GOALS.size());
            DataStore.setGoal(GOALS[_goalIdx]);
        } else if (_cursor == ITEM_INTERVAL) {
            _intrIdx = _wrapIndex(_intrIdx + direction, INTERVALS.size());
            DataStore.setInterval(INTERVALS[_intrIdx]);
        } else if (_cursor == ITEM_UNITS) {
            _unitsIdx = _wrapIndex(_unitsIdx + direction, 2);
            DataStore.setUnits(_unitsIdx);
        }
        WatchUi.requestUpdate();
    }

    private function _intervalLabel(minutes as Number) as String {
        if (minutes == 0) {
            return WatchUi.loadResource(Rez.Strings.IntervalOff) as String;
        }
        return minutes.toString() + " min";
    }

    private function _findIndex(arr as Array<Number>, value as Number) as Number {
        for (var i = 0; i < arr.size(); i++) {
            if (arr[i] == value) { return i; }
        }
        return 0;
    }

    private function _wrapIndex(idx as Number, size as Number) as Number {
        return ((idx % size) + size) % size;
    }
}

// Делегат настроек
class SettingsDelegate extends WatchUi.BehaviorDelegate {

    private var _view as SettingsView;

    function initialize() {
        BehaviorDelegate.initialize();
        _view = WatchUi.getCurrentView()[0] as SettingsView;
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

    // SELECT — увеличить значение
    function onSelect() as Boolean {
        _view.changeValue(1);
        return true;
    }

    // BACK — сохранить и вернуться
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
