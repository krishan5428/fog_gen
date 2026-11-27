<?php

class FogshieldEventFilter {

    // ── 4G Com Dashboard (001) state-diff lookup ───────────────────────
    public static function fourgDashboard(string $field, string $code, string $site, string $extra = ""): ?array {

        $xmlPath = __DIR__ . '/4gcom_events.xml';
        if (!file_exists($xmlPath)) return null;

        $xml = simplexml_load_file($xmlPath);

        foreach ($xml->xpath("//packet[@id='001']/$field") as $node) {
            if ((string)$node['code'] === $code) {
                if ((string)$node['notify'] !== 'true') return null;

                $desc = str_replace('{input}', $extra, (string)$node['body']);
                $time = date('h:i A d/m/Y');

                return [
                    'title' => "Alert — $site",
                    'body'  => "$desc\n$time",
                    'event' => strtoupper($field) . '_' . $code,
                ];
            }
        }
        return null;
    }

    // ── 4G Com Write Response (all settings/control packets) ──────────
    // Handles packet type 04 for all packet IDs except 001 (dashboard).
    public static function fourgWriteResponse(
        string $packetId,
        array  $parts,
        string $site
    ): ?array {

        $xmlPath = __DIR__ . '/4gcom_events.xml';
        if (!file_exists($xmlPath)) return null;

        $xml = simplexml_load_file($xmlPath);

        // Helper: map output number string to human label (081→1, 001→1 etc.)
        $outputLabel = function(string $raw): string {
            $n = (int)ltrim($raw, '0') ?: 0;
            // SA outputs: 081–084 → Output 1–4
            if ($n >= 81 && $n <= 84) return (string)($n - 80);
            // 2-way outputs: 001–004 → Output 1–4
            if ($n >= 1 && $n <= 4)   return (string)$n;
            return $raw;
        };

        // ── Packets with function_id in parts[5] ──────────────────────
        // 003 (Health), 006 (Reset), 009 (Audio), 013 (Hub), 015 (Log clear), 016 (Log clear)
        $functionIdPackets = ['003', '006', '009', '013', '015', '016'];

        $time = date('h:i A d/m/Y');

        if (in_array($packetId, $functionIdPackets)) {
            $functionId = trim($parts[5] ?? '');
            foreach ($xml->xpath("//packet[@id='$packetId']/function_id") as $node) {
                if ((string)$node['code'] === $functionId) {
                    if ((string)$node['notify'] !== 'true') return null;
                    return [
                        'title' => "Alert — $site",
                        'body'  => (string)$node['body'] . "\n$time",
                        'event' => "PKT{$packetId}_FID{$functionId}",
                    ];
                }
            }
            return null;
        }

        // ── Packet 014 — pending queue clear, source in parts[6] ──────
        if ($packetId === '014') {
            $source = trim($parts[6] ?? '');
            foreach ($xml->xpath("//packet[@id='014']/pending_source") as $node) {
                if ((string)$node['code'] === $source) {
                    if ((string)$node['notify'] !== 'true') return null;
                    return [
                        'title' => "Alert — $site",
                        'body'  => (string)$node['body'] . "\n$time",
                        'event' => "PKT014_SRC{$source}",
                    ];
                }
            }
            return null;
        }

        // ── Packet 010 — input settings, input_no in parts[6] ─────────
        if ($packetId === '010') {
            $inputNo = ltrim(trim($parts[6] ?? ''), '0') ?: '0';
            $nodes = $xml->xpath("//packet[@id='010']/write_response");
            if (empty($nodes) || (string)$nodes[0]['notify'] !== 'true') return null;
            $desc = str_replace('{input_no}', $inputNo, (string)$nodes[0]['body']);
            return [
                'title' => "Alert — $site",
                'body'  => "$desc\n$time",
                'event' => "PKT010_IN{$inputNo}",
            ];
        }

        // ── Packet 011 — output settings, output_no in parts[5] ───────
        if ($packetId === '011') {
            $nodes = $xml->xpath("//packet[@id='011']/write_response");
            if (empty($nodes) || (string)$nodes[0]['notify'] !== 'true') return null;
            return [
                'title' => "Alert — $site",
                'body'  => (string)$nodes[0]['body'] . "\n$time",
                'event' => 'PKT011_OUTPUT_SETTINGS',
            ];
        }

        // ── Packet 012 — output control, output_no in parts[5] ────────
        if ($packetId === '012') {
            $outputNo = $outputLabel(trim($parts[5] ?? ''));
            $nodes = $xml->xpath("//packet[@id='012']/output[@code='$outputNo']");
            if (empty($nodes)) {
                $nodes = $xml->xpath("//packet[@id='012']/write_response");
            }
            if (empty($nodes) || (string)$nodes[0]['notify'] !== 'true') return null;
            $desc = str_replace('{output_no}', $outputNo, (string)$nodes[0]['body']);
            return [
                'title' => "Alert — $site",
                'body'  => "$desc\n$time",
                'event' => "PKT012_OUT{$outputNo}",
            ];
        }

        // ── Packet 021 — group-2 alert settings, alert_ref in parts[5] ─
        if ($packetId === '021') {
            $alertRef = ltrim(trim($parts[5] ?? ''), '0') ?: '0';
            $nodes = $xml->xpath("//packet[@id='021']/write_response");
            if (empty($nodes) || (string)$nodes[0]['notify'] !== 'true') return null;
            $desc = str_replace('{alert_ref}', $alertRef, (string)$nodes[0]['body']);
            return [
                'title' => "Alert — $site",
                'body'  => "$desc\n$time",
                'event' => "PKT021_REF{$alertRef}",
            ];
        }

        // ── Simple write_response packets (002, 004, 007, 008, 017, 018, 019, 020) ──
        $nodes = $xml->xpath("//packet[@id='$packetId']/write_response");
        if (empty($nodes)) return null;
        if ((string)$nodes[0]['notify'] !== 'true') return null;

        return [
            'title' => "Alert — $site",
            'body'  => (string)$nodes[0]['body'] . "\n$time",
            'event' => "PKT{$packetId}_UPDATED",
        ];
    }
}
?>
