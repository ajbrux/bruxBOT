//mappers/raidMapper.js
import fs from 'node:fs';
import path from 'node:path';


export function RaidMapper(dir = path.resolve('assets', 'raids')) {
    const RAID_MAP = {};

    if (!fs.existsSync(dir)) {
        return RAID_MAP;
    }

    const files = fs.readdirSync(dir);
    for (const file of files) {
        const lower = file.toLowerCase();
        if (lower.endsWith('.mp3') || lower.endsWith('.wav')) {
            const key = lower.replace('.mp3', '').replace('.wav', '');
            map[key] = path.join(dir, file);
        }
    }

    return RAID_MAP;
}
