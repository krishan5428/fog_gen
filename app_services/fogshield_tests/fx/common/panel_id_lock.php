<?php
// Test stand-in: ids listed in FS_LOCKED (comma separated) are locked.
function isPanelIdLocked($id) {
    $locked = array_filter(array_map('intval', explode(',', getenv('FS_LOCKED') ?: '')));
    return in_array((int)$id, $locked, true);
}
