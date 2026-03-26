// SettingsView.mc — главное меню настроек
import Toybox.Lang;
import Toybox.WatchUi;

// =============================================================================
// Главное меню Settings: Units / Formula

function pushSettingsMenu() as Void {
    var menu = new WatchUi.Menu2({});
    menu.addItem(new WatchUi.MenuItem("Units", (DataStore.getUnits() == 0) ? "ml" : "oz", :units, {}));
    menu.addItem(new WatchUi.MenuItem("Formula", null, :formula, {}));
    WatchUi.pushView(menu, new MainSettingsDelegate(), WatchUi.SLIDE_DOWN);
}

class MainSettingsDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :units) {
            var newUnits = (DataStore.getUnits() == 0) ? 1 : 0;
            DataStore.setUnits(newUnits);
            item.setSubLabel((newUnits == 0) ? "ml" : "oz");
        } else if (id == :formula) {
            pushDebugProfileView();
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
