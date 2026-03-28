"""
generate_stems.py — Programmatic stem generation for dance-to-music POC.

Generates 12 WAV files (3 genres x 4 stems each) using pure numpy synthesis.
Each genre has: drums, bass, melody, pad — all same BPM and key (C minor).

BPM targets: EDM=128, Lo-fi=85, Hip-hop=95
Key: C minor (C Eb F G Bb)
Duration: 8 bars each, seamlessly loopable

Usage: python ml/generate_stems.py
Output: assets/stems/{edm,lofi,hiphop}/{drums,bass,melody,pad}.wav
"""

import numpy as np
from scipy.io import wavfile
import os

SR = 44100  # Sample rate
SCALE_CM = [261.63, 311.13, 349.23, 392.00, 466.16]  # C4 Eb4 F4 G4 Bb4


def note_freq(name):
    """Convert note name to frequency. e.g. 'C2' -> 65.41"""
    notes = {'C': 0, 'D': 2, 'Eb': 3, 'E': 4, 'F': 5, 'G': 7, 'Ab': 8, 'A': 9, 'Bb': 10, 'B': 11}
    note = name[:-1]
    octave = int(name[-1])
    semitone = notes[note] + (octave - 4) * 12
    return 261.63 * (2 ** (semitone / 12))


def sine(freq, duration, sr=SR):
    t = np.linspace(0, duration, int(sr * duration), endpoint=False)
    return np.sin(2 * np.pi * freq * t)


def saw(freq, duration, sr=SR, harmonics=8):
    t = np.linspace(0, duration, int(sr * duration), endpoint=False)
    wave = np.zeros_like(t)
    for k in range(1, harmonics + 1):
        wave += ((-1) ** (k + 1)) * np.sin(2 * np.pi * k * freq * t) / k
    return wave * (2 / np.pi)


def square(freq, duration, sr=SR, harmonics=6):
    t = np.linspace(0, duration, int(sr * duration), endpoint=False)
    wave = np.zeros_like(t)
    for k in range(1, harmonics * 2, 2):
        wave += np.sin(2 * np.pi * k * freq * t) / k
    return wave * (4 / np.pi)


def noise(duration, sr=SR):
    return np.random.randn(int(sr * duration))


def envelope(signal, attack=0.005, decay=0.05, sustain=0.7, release=0.1, sr=SR):
    n = len(signal)
    env = np.ones(n)
    a = int(attack * sr)
    d = int(decay * sr)
    r = int(release * sr)
    # Attack
    if a > 0:
        env[:a] = np.linspace(0, 1, a)
    # Decay
    if d > 0 and a + d < n:
        env[a:a + d] = np.linspace(1, sustain, d)
    # Sustain
    if a + d < n - r:
        env[a + d:n - r] = sustain
    # Release
    if r > 0:
        env[n - r:] = np.linspace(sustain, 0, r)
    return signal * env


def lowpass(signal, cutoff, sr=SR):
    """Simple 1-pole low-pass filter."""
    alpha = 1.0 / (1.0 + sr / (2 * np.pi * cutoff))
    out = np.zeros_like(signal)
    out[0] = signal[0] * alpha
    for i in range(1, len(signal)):
        out[i] = out[i - 1] + alpha * (signal[i] - out[i - 1])
    return out


def highpass(signal, cutoff, sr=SR):
    return signal - lowpass(signal, cutoff, sr)


def mix_at(target, source, start_sample, volume=1.0):
    """Mix source into target at given sample offset."""
    end = min(start_sample + len(source), len(target))
    length = end - start_sample
    if length > 0:
        target[start_sample:end] += source[:length] * volume


def bars_to_samples(bars, bpm, sr=SR):
    """Convert bars to sample count (4/4 time)."""
    beats = bars * 4
    return int(beats * 60 / bpm * sr)


def beat_to_sample(beat, bpm, sr=SR):
    """Convert beat number to sample position."""
    return int(beat * 60 / bpm * sr)


# =====================================================================
# EDM STEMS (128 BPM, C minor, 8 bars)
# =====================================================================

def generate_edm_drums(bpm=128, bars=8):
    total = bars_to_samples(bars, bpm)
    out = np.zeros(total)
    total_beats = bars * 4

    for beat in range(total_beats):
        pos = beat_to_sample(beat, bpm)

        # Kick on every beat (four-on-the-floor)
        kick_dur = 0.15
        kick = sine(55, kick_dur) * np.exp(-np.linspace(0, 8, int(SR * kick_dur)))
        click_dur = 0.05
        click = sine(110, click_dur) * np.exp(-np.linspace(0, 15, int(SR * click_dur)))
        mix_at(out, kick, pos, 0.7)
        mix_at(out, click, pos, 0.4)

        # Clap on beats 2 and 4
        if beat % 4 in [1, 3]:
            clap = noise(0.04) * np.exp(-np.linspace(0, 12, int(SR * 0.04)))
            clap = highpass(clap, 1000)
            mix_at(out, clap, pos, 0.3)

        # Hi-hat on every 8th note
        for sub in range(2):
            hat_pos = pos + beat_to_sample(sub * 0.5, bpm)
            hat = noise(0.03) * np.exp(-np.linspace(0, 20, int(SR * 0.03)))
            hat = highpass(hat, 6000)
            vol = 0.15 if sub == 0 else 0.08
            mix_at(out, hat, hat_pos, vol)

        # Open hat on the "and" of beat 2 and 4
        if beat % 4 in [1, 3]:
            ohat_pos = pos + beat_to_sample(0.5, bpm)
            ohat = noise(0.12) * np.exp(-np.linspace(0, 6, int(SR * 0.12)))
            ohat = highpass(ohat, 5000)
            mix_at(out, ohat, ohat_pos, 0.12)

    return np.clip(out, -1, 1)


def generate_edm_bass(bpm=128, bars=8):
    total = bars_to_samples(bars, bpm)
    out = np.zeros(total)
    # 2-bar bass pattern, repeated
    pattern = ['C2', 'C2', 'Eb2', 'Eb2', 'F2', 'F2', 'G2', 'Bb1']

    for bar in range(bars):
        for beat in range(4):
            pos = beat_to_sample(bar * 4 + beat, bpm)
            note = pattern[(bar % 2) * 4 + beat]
            freq = note_freq(note)
            dur = 60 / bpm * 0.8
            bass = saw(freq, dur, harmonics=4)
            bass = lowpass(bass, 300)
            bass = envelope(bass, attack=0.005, decay=0.1, sustain=0.6, release=0.05)
            mix_at(out, bass, pos, 0.5)

    return np.clip(out, -1, 1)


def generate_edm_melody(bpm=128, bars=8):
    total = bars_to_samples(bars, bpm)
    out = np.zeros(total)
    # Arpeggiated synth pattern — 16th notes
    arp_notes = ['C5', 'Eb5', 'G5', 'Bb5', 'G5', 'Eb5', 'F5', 'G5',
                 'Bb5', 'G5', 'F5', 'Eb5', 'C5', 'Eb5', 'F5', 'G5']

    for bar in range(bars):
        for sixteenth in range(16):
            pos = beat_to_sample(bar * 4 + sixteenth * 0.25, bpm)
            note = arp_notes[sixteenth % len(arp_notes)]
            freq = note_freq(note)
            dur = 60 / bpm * 0.2
            tone = saw(freq, dur, harmonics=3)
            tone = lowpass(tone, 4000)
            tone = envelope(tone, attack=0.005, decay=0.08, sustain=0.3, release=0.05)
            # Accent pattern: louder on beats
            vol = 0.25 if sixteenth % 4 == 0 else 0.15
            mix_at(out, tone, pos, vol)

    return np.clip(out, -1, 1)


def generate_edm_pad(bpm=128, bars=8):
    total = bars_to_samples(bars, bpm)
    out = np.zeros(total)
    # Sustained chord changes every 2 bars
    chords = [
        ['C4', 'Eb4', 'G4'],       # Cm
        ['F3', 'Ab3', 'C4'],       # Fm
        ['Ab3', 'C4', 'Eb4'],      # Ab
        ['Bb3', 'D4', 'F4'],       # Bb
    ]

    for i, chord in enumerate(chords):
        start = bars_to_samples(i * 2, bpm)
        dur = 2 * 4 * 60 / bpm  # 2 bars duration
        for note_name in chord:
            freq = note_freq(note_name)
            tone = sine(freq, dur) * 0.5 + sine(freq * 1.003, dur) * 0.3  # slight detune for width
            tone = envelope(tone, attack=0.5, decay=0.2, sustain=0.8, release=0.5)
            mix_at(out, tone, start, 0.15)

    return np.clip(out, -1, 1)


# =====================================================================
# LO-FI STEMS (85 BPM, C minor, 8 bars)
# =====================================================================

def generate_lofi_drums(bpm=85, bars=8):
    total = bars_to_samples(bars, bpm)
    out = np.zeros(total)
    total_beats = bars * 4

    for beat in range(total_beats):
        pos = beat_to_sample(beat, bpm)

        # Kick on 1 and 3 (with slight swing)
        if beat % 4 in [0, 2]:
            kick = sine(45, 0.2) * np.exp(-np.linspace(0, 6, int(SR * 0.2)))
            kick = lowpass(kick, 200)
            mix_at(out, kick, pos, 0.5)

        # Snare on 2 and 4 (vinyl-textured)
        if beat % 4 in [1, 3]:
            snr_dur = 0.12
            snare = noise(snr_dur) * np.exp(-np.linspace(0, 8, int(SR * snr_dur)))
            snare = lowpass(snare, 3000)
            snr_body = sine(200, 0.06) * np.exp(-np.linspace(0, 12, int(SR * 0.06)))
            mix_at(out, snare, pos, 0.25)
            mix_at(out, snr_body, pos, 0.15)

        # Soft hi-hat shuffle (swung 8ths)
        for sub in range(2):
            swing = 0.02 if sub == 1 else 0.0  # slight swing feel
            hat_pos = pos + beat_to_sample(sub * 0.5, bpm) + int(swing * SR)
            hat = noise(0.025) * np.exp(-np.linspace(0, 25, int(SR * 0.025)))
            hat = highpass(hat, 7000)
            hat = lowpass(hat, 12000)  # lo-fi filter
            vol = 0.1 if sub == 0 else 0.06
            mix_at(out, hat, hat_pos, vol)

    # Add vinyl crackle layer
    crackle = noise(total / SR) * 0.008
    crackle = highpass(crackle, 2000)
    out += crackle

    return np.clip(out, -1, 1)


def generate_lofi_bass(bpm=85, bars=8):
    total = bars_to_samples(bars, bpm)
    out = np.zeros(total)
    # Mellow bass, half notes
    pattern = ['C2', 'Eb2', 'F2', 'Bb1', 'C2', 'G1', 'Ab1', 'Bb1']

    for bar in range(bars):
        pos = beat_to_sample(bar * 4, bpm)
        note = pattern[bar % len(pattern)]
        freq = note_freq(note)
        dur = 4 * 60 / bpm * 0.9  # nearly full bar
        bass = sine(freq, dur)
        bass = envelope(bass, attack=0.02, decay=0.3, sustain=0.5, release=0.2)
        bass = lowpass(bass, 250)
        mix_at(out, bass, pos, 0.4)

    return np.clip(out, -1, 1)


def generate_lofi_melody(bpm=85, bars=8):
    total = bars_to_samples(bars, bpm)
    out = np.zeros(total)
    # Rhodes-like electric piano, sparse melody
    melody = [
        (0, 'Eb5', 1.0), (1.5, 'G5', 0.5), (2, 'F5', 1.0),
        (4, 'C5', 0.75), (5, 'Bb4', 0.5), (6, 'G4', 1.5),
        (8, 'Eb5', 1.0), (9, 'F5', 0.5), (10, 'G5', 1.5),
        (12, 'Bb5', 0.75), (13, 'G5', 0.5), (14, 'Eb5', 1.0),
        (16, 'C5', 1.5), (18, 'Eb5', 0.5), (19, 'F5', 1.0),
        (20, 'G5', 0.75), (21, 'F5', 0.5), (22, 'Eb5', 1.5),
        (24, 'C5', 1.0), (25.5, 'Bb4', 0.5), (26, 'G4', 1.5),
        (28, 'Ab4', 1.0), (29, 'Bb4', 0.5), (30, 'C5', 1.5),
    ]

    for beat, note_name, dur in melody:
        pos = beat_to_sample(beat, bpm)
        freq = note_freq(note_name)
        note_dur = dur * 60 / bpm
        # Rhodes: sine + slight bell harmonic
        tone = sine(freq, note_dur) * 0.7
        bell = sine(freq * 2, note_dur) * 0.15 * np.exp(-np.linspace(0, 8, int(SR * note_dur)))
        tone = tone + bell
        tone = envelope(tone, attack=0.01, decay=0.2, sustain=0.3, release=0.15)
        tone = lowpass(tone, 3000)  # warm lo-fi character
        mix_at(out, tone, pos, 0.25)

    return np.clip(out, -1, 1)


def generate_lofi_pad(bpm=85, bars=8):
    total = bars_to_samples(bars, bpm)
    out = np.zeros(total)
    # Warm sustained chords, 2 bars each
    chords = [
        ['C3', 'Eb3', 'G3', 'Bb3'],    # Cm7
        ['F3', 'Ab3', 'C4', 'Eb4'],    # Fm7
        ['Ab3', 'C4', 'Eb4', 'G4'],    # AbMaj7
        ['Bb3', 'D4', 'F4', 'Ab4'],    # Bb7
    ]

    for i, chord in enumerate(chords):
        start = bars_to_samples(i * 2, bpm)
        dur = 2 * 4 * 60 / bpm
        for note_name in chord:
            freq = note_freq(note_name)
            tone = sine(freq, dur)
            tone = envelope(tone, attack=1.0, decay=0.3, sustain=0.7, release=1.0)
            mix_at(out, tone, start, 0.1)

    # Lo-fi filter warmth
    out = lowpass(out, 2500)

    return np.clip(out, -1, 1)


# =====================================================================
# HIP-HOP STEMS (95 BPM, C minor, 8 bars)
# =====================================================================

def generate_hiphop_drums(bpm=95, bars=8):
    total = bars_to_samples(bars, bpm)
    out = np.zeros(total)
    total_beats = bars * 4

    for beat in range(total_beats):
        pos = beat_to_sample(beat, bpm)
        bar_beat = beat % 4

        # Kick pattern: boom-bap style (1, 2.5, 3)
        if bar_beat == 0:
            k_dur = 0.18
            kick = sine(50, k_dur) * np.exp(-np.linspace(0, 7, int(SR * k_dur)))
            k_click = sine(100, 0.04) * np.exp(-np.linspace(0, 20, int(SR * 0.04)))
            mix_at(out, kick, pos, 0.65)
            mix_at(out, k_click, pos, 0.3)
        elif bar_beat == 2:
            k_dur = 0.15
            kick = sine(50, k_dur) * np.exp(-np.linspace(0, 7, int(SR * k_dur)))
            mix_at(out, kick, pos, 0.55)

        # Ghost kick on the "and" of 2
        if bar_beat == 1:
            ghost_pos = pos + beat_to_sample(0.5, bpm)
            kick = sine(50, 0.12) * np.exp(-np.linspace(0, 9, int(SR * 0.12)))
            mix_at(out, kick, ghost_pos, 0.35)

        # Snare on 2 and 4
        if bar_beat in [1, 3]:
            snr_dur = 0.15
            snare = noise(snr_dur) * np.exp(-np.linspace(0, 6, int(SR * snr_dur)))
            snare = lowpass(snare, 5000)
            snr_body = sine(180, 0.08) * np.exp(-np.linspace(0, 10, int(SR * 0.08)))
            mix_at(out, snare, pos, 0.35)
            mix_at(out, snr_body, pos, 0.2)

        # Hi-hat: 16th note pattern with accents
        for sixteenth in range(4):
            hat_pos = pos + beat_to_sample(sixteenth * 0.25, bpm)
            dur = 0.02 if sixteenth % 2 == 0 else 0.015
            hat = noise(dur) * np.exp(-np.linspace(0, 30, int(SR * dur)))
            hat = highpass(hat, 8000)
            vol = 0.12 if sixteenth == 0 else 0.06
            mix_at(out, hat, hat_pos, vol)

    return np.clip(out, -1, 1)


def generate_hiphop_bass(bpm=95, bars=8):
    total = bars_to_samples(bars, bpm)
    out = np.zeros(total)
    # 808-style sub bass, follows kick pattern
    pattern = [
        (0, 'C2', 1.5), (1.5, 'C2', 0.5),
        (2, 'Eb2', 1.0), (3, 'Bb1', 1.0),
    ]

    for bar in range(bars):
        for beat_off, note_name, dur in pattern:
            pos = beat_to_sample(bar * 4 + beat_off, bpm)
            freq = note_freq(note_name)
            note_dur = dur * 60 / bpm
            bass = sine(freq, note_dur)
            # 808 slide on some notes
            if beat_off == 0 and bar % 2 == 1:
                n_samples = int(SR * note_dur)
                t = np.linspace(0, note_dur, n_samples, endpoint=False)
                slide_freq = np.linspace(freq, freq * 0.95, n_samples)
                bass = np.sin(2 * np.pi * np.cumsum(slide_freq) / SR)
            bass = envelope(bass, attack=0.005, decay=0.1, sustain=0.7, release=0.1)
            bass = lowpass(bass, 200)
            mix_at(out, bass, pos, 0.5)

    return np.clip(out, -1, 1)


def generate_hiphop_melody(bpm=95, bars=8):
    total = bars_to_samples(bars, bpm)
    out = np.zeros(total)
    # Dark piano hits, sparse and rhythmic
    melody = [
        (0, 'C4', 0.5), (0.5, 'Eb4', 0.25), (1, 'G4', 0.75),
        (2, 'F4', 0.5), (3, 'Eb4', 1.0),
        (4, 'Bb4', 0.5), (4.75, 'G4', 0.25), (5, 'F4', 0.75),
        (6, 'Eb4', 0.5), (7, 'C4', 1.0),
        (8, 'C4', 0.5), (8.5, 'Eb4', 0.25), (9, 'G4', 0.75),
        (10, 'Bb4', 0.5), (11, 'Ab4', 1.0),
        (12, 'G4', 0.5), (12.75, 'F4', 0.25), (13, 'Eb4', 0.75),
        (14, 'C4', 0.5), (15, 'Bb3', 1.0),
        # Second half (variation)
        (16, 'C5', 0.5), (16.5, 'Bb4', 0.25), (17, 'G4', 0.75),
        (18, 'F4', 0.5), (19, 'Eb4', 1.0),
        (20, 'C4', 0.75), (21, 'Eb4', 0.5), (22, 'F4', 0.75),
        (23, 'G4', 1.0),
        (24, 'Ab4', 0.5), (24.75, 'G4', 0.25), (25, 'F4', 0.75),
        (26, 'Eb4', 0.5), (27, 'C4', 1.0),
        (28, 'Bb3', 0.75), (29, 'C4', 0.5), (30, 'Eb4', 1.0),
        (31, 'C4', 1.0),
    ]

    for beat, note_name, dur in melody:
        pos = beat_to_sample(beat, bpm)
        freq = note_freq(note_name)
        note_dur = dur * 60 / bpm
        # Dark piano tone: triangle-ish
        tone = sine(freq, note_dur) * 0.6 + sine(freq * 2, note_dur) * 0.2 + sine(freq * 3, note_dur) * 0.05
        tone = envelope(tone, attack=0.005, decay=0.15, sustain=0.2, release=0.1)
        mix_at(out, tone, pos, 0.3)

    return np.clip(out, -1, 1)


def generate_hiphop_pad(bpm=95, bars=8):
    total = bars_to_samples(bars, bpm)
    out = np.zeros(total)
    # Dark ambient pad with minor chords
    chords = [
        ['C3', 'Eb3', 'G3'],       # Cm
        ['Ab2', 'C3', 'Eb3'],      # Ab
        ['Bb2', 'D3', 'F3'],       # Bb
        ['G2', 'Bb2', 'D3'],       # Gm
    ]

    for i, chord in enumerate(chords):
        start = bars_to_samples(i * 2, bpm)
        dur = 2 * 4 * 60 / bpm
        for note_name in chord:
            freq = note_freq(note_name)
            # Dark, filtered pad
            tone = sine(freq, dur) * 0.6 + saw(freq, dur, harmonics=3) * 0.15
            tone = lowpass(tone, 1500)
            tone = envelope(tone, attack=0.8, decay=0.3, sustain=0.6, release=0.8)
            mix_at(out, tone, start, 0.12)

    return np.clip(out, -1, 1)


# =====================================================================
# Main: Generate all stems
# =====================================================================

def save_wav(filepath, audio, sr=SR):
    """Save float64 audio as 16-bit WAV."""
    audio = np.clip(audio, -1, 1)
    audio_16 = (audio * 32767).astype(np.int16)
    wavfile.write(filepath, sr, audio_16)
    size_kb = os.path.getsize(filepath) / 1024
    print(f"  {filepath} ({size_kb:.0f} KB)")


def main():
    base = os.path.join(os.path.dirname(__file__), '..', 'assets', 'stems')

    genres = {
        'edm': {
            'drums': generate_edm_drums,
            'bass': generate_edm_bass,
            'melody': generate_edm_melody,
            'pad': generate_edm_pad,
        },
        'lofi': {
            'drums': generate_lofi_drums,
            'bass': generate_lofi_bass,
            'melody': generate_lofi_melody,
            'pad': generate_lofi_pad,
        },
        'hiphop': {
            'drums': generate_hiphop_drums,
            'bass': generate_hiphop_bass,
            'melody': generate_hiphop_melody,
            'pad': generate_hiphop_pad,
        },
    }

    for genre, stems in genres.items():
        print(f"\n--- {genre.upper()} ---")
        genre_dir = os.path.join(base, genre)
        os.makedirs(genre_dir, exist_ok=True)

        for stem_name, gen_func in stems.items():
            audio = gen_func()
            filepath = os.path.join(genre_dir, f'{stem_name}.wav')
            save_wav(filepath, audio)

    print(f"\nDone! Generated {sum(len(s) for s in genres.values())} stems.")


if __name__ == '__main__':
    main()
