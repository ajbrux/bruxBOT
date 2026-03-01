//osdetector/osDetector.js
export function detectOS() {
    const p = process.platform;
    if (p === 'win32') return 'windows';
    if (p === 'darwin') return 'mac';
    return 'linux';
}
