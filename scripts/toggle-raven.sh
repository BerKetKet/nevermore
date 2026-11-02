#!/bin/bash
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
for (let id of panelIds) {
    let p = panelById(id);
    if (p && p.location === 'right') {
        p.hiding = (p.hiding === 'autohide' ? 'none' : 'autohide');
        print('Toggled panel ' + id + ' to ' + p.hiding);
        break;
    }
}
"
