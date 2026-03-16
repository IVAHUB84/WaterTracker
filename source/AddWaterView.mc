// AddWaterView.mc — выбор порции воды
import Toybox.Lang;
import Toybox.WatchUi;

// Объёмы для Custom-меню (мл), отрицательные = вычесть
var CUSTOM_AMOUNTS as Array<Number> =
    [50, 75, 100, 125, 150, 175, 200, 250, 300, 350, 400, 450,
     500, 600, 700, 800, 900, 1000, 1200, 1500, 2000] as Array<Number>;

// =============================================================================
// Меню выбора порции

function pushAddWaterMenu() as Void {
    var units = DataStore.getUnits();
    var menu  = new WatchUi.Menu2({:title => "Add Water"});

    menu.addItem(new WatchUi.MenuItem(_fmtPortion(150, units), null, 150, {}));
    menu.addItem(new WatchUi.MenuItem(_fmtPortion(250, units), null, 250, {}));
    menu.addItem(new WatchUi.MenuItem(_fmtPortion(500, units), null, 500, {}));
    menu.addItem(new WatchUi.MenuItem("Custom...",             null, 0,   {}));

    WatchUi.pushView(menu, new AddWaterMenuDelegate(), WatchUi.SLIDE_UP);
}

function _fmtPortion(ml as Number, units as Number) as String {
    var sign = (ml >= 0) ? "+" : "";
    if (units == 0) { return sign + ml.toString() + " ml"; }
    return sign + (ml.toFloat() / 29.5735f).format("%.1f") + " oz";
}

// =============================================================================
// Делегат меню выбора порции

class AddWaterMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId() as Number;
        if (id == 0) {
            // Custom — открыть второе меню со списком объёмов
            _pushCustomMenu();
        } else {
            // Фиксированная порция — добавить/убрать и вернуться
            DataStore.addAmount(id);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    private function _pushCustomMenu() as Void {
        var units = DataStore.getUnits();
        var menu  = new WatchUi.Menu2({:title => "Custom"});
        for (var i = 0; i < CUSTOM_AMOUNTS.size(); i++) {
            var ml = CUSTOM_AMOUNTS[i];
            menu.addItem(new WatchUi.MenuItem(_fmtPortion(ml, units), null, ml, {}));
        }
        WatchUi.pushView(menu, new CustomMenuDelegate(), WatchUi.SLIDE_UP);
    }
}

// =============================================================================
// Делегат Custom-меню (список нестандартных объёмов)

class CustomMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var ml = item.getId() as Number;
        DataStore.addAmount(ml);
        // Закрыть Custom-меню и Add Water меню — вернуться на главный экран
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
