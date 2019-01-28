function tauhead_localStorage_check() {
    // Example copied from
    // https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API/Using_the_Web_Storage_API
    var type="localStorage";

    try {
        var storage = window[type],
            x = '__storage_test__';
        storage.setItem(x, x);
        storage.removeItem(x);
        return true;
    }
    catch(e) {
        return e instanceof DOMException && (
            // everything except Firefox
            e.code === 22 ||
            // Firefox
            e.code === 1014 ||
            // test name field too, because code might not be present
            // everything except Firefox
            e.name === 'QuotaExceededError' ||
            // Firefox
            e.name === 'NS_ERROR_DOM_QUOTA_REACHED') &&
            // acknowledge QuotaExceededError only if there's something already stored
            storage.length !== 0;
    }
}

function tauhead_list_item_hide_opts_get( item_type ) {
    if ( !tauhead_localStorage_check() ) {
        return new Object;
    }

    var key   = tauhead_list_item_hide_opts_key( item_type );
    var value = localStorage.getItem( key );

    if ( !value ) {
        return new Object;
    }

    value = JSON.parse( value );
    return value;
}

function tauhead_list_item_hide_opts_set( item_type, object ) {
    if ( !tauhead_localStorage_check() ) {
        return;
    }

    var key   = tauhead_list_item_hide_opts_key( item_type );
    var value = JSON.stringify(object);
    localStorage.setItem( key, value );
}

function tauhead_list_item_hide_opts_key( item_type ) {
    var key = "list_item_hide_opts";

    if ( 'weapon' === item_type ) {
        key = "list_item_hide_weapon_opts";
    }
    else if ( 'armor' === item_type ) {
        key = "list_item_hide_armor_opts";
    }
    else if ( 'medical' === item_type ) {
        key = "list_item_hide_medical_opts";
    }
    // Any other item_type just gets default opts

    return key;
}
