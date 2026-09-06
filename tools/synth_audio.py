#!/usr/bin/env python3
"""سنتز صداهای بازینو — تولید WAV برکانی از ریاضی (بدون فایل منبع خارجی).

اجرا:  server/.venv/bin/python tools/synth_audio.py
خروجی: godot/assets/audio/*.wav  (22050Hz مونو 16bit)
"""
import wave
import struct
import math
import os

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "godot", "assets", "audio")


def t(sec: float) -> np.ndarray:
    return np.arange(int(SR * sec)) / SR


def env_decay(n: int, curve: float = 3.0) -> np.ndarray:
    return np.exp(-curve * np.linspace(0.0, 1.0, n))


def fade_in_out(x: np.ndarray, f: int = 64) -> np.ndarray:
    x = x.copy()
    if len(x) > 2 * f:
        x[:f] *= np.linspace(0, 1, f)
        x[-f:] *= np.linspace(1, 0, f)
    return x


def sine(f):  # موج سینوسی با فرکانس (آرایه‌ای یا عدد)
    return lambda tt: np.sin(2 * np.pi * f * tt)


def saw(f):
    return lambda tt: 2.0 * ((f * tt) % 1.0) - 1.0


def square(f):
    return lambda tt: np.sign(np.sin(2 * np.pi * f * tt))


def sweep(f0, f1, sec, osc=sine, curve=3.0, gain=0.8):
    tt = t(sec)
    ph = np.cumsum(np.linspace(f0, f1, len(tt))) / SR
    x = osc(1.0)(ph)
    return gain * env_decay(len(tt), curve) * x


def noise(sec, gain=0.6, curve=4.0, lp=0.25):
    n = int(SR * sec)
    rng = np.random.default_rng(44)
    x = rng.standard_normal(n)
    # پایین‌گذر سادهٔ تک‌قطبی
    y = np.copy(x)
    for i in range(1, n):
        y[i] = lp * x[i] + (1 - lp) * y[i - 1]
    return gain * env_decay(n, curve) * y


def chord(freqs, sec, gain=0.5, curve=2.2):
    tt = t(sec)
    x = sum(sine(f)(tt) + 0.35 * sine(f * 2)(tt) for f in freqs) / len(freqs)
    return gain * env_decay(len(tt), curve) * x


def pluck(freqs, sec=0.25, gap=0.07, gain=0.55):
    n = int(SR * (sec + gap * (len(freqs) - 1)))
    out = np.zeros(n)
    for i, f in enumerate(freqs):
        k = int(i * gap * SR)
        seg = 0.8 * sine(f)(t(sec)) * env_decay(int(SR * sec), 6.0)
        out[k:k + len(seg)] += seg
    return gain * out / max(1.0, np.abs(out).max())


def blend(*parts: np.ndarray) -> np.ndarray:
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def save(name: str, x: np.ndarray) -> None:
    os.makedirs(OUT, exist_ok=True)
    x = fade_in_out(np.clip(x, -1.0, 1.0))
    data = (x * 32767).astype(np.int16)
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(f"✓ {name}  ({len(x)/SR:.2f}s, {os.path.getsize(path)//1024}KB)")


# ───────────── افکت‌ها ─────────────
save("jump.wav", sweep(240, 520, 0.18) * 0.9)
save("land.wav", blend(0.9 * sweep(160, 60, 0.14), 0.35 * noise(0.08, lp=0.2)))
save("dash.wav", noise(0.22, gain=0.8, curve=2.5, lp=0.5) *
     (1 + 0.5 * sine(30)(t(0.22))))
tt_a = t(0.16)
save("attack.wav", blend(0.75 * saw(850)(tt_a) * env_decay(len(tt_a), 9.0) *
     (1 + 0.4 * sine(90)(tt_a)), 0.3 * noise(0.1, lp=0.6)))
save("hurt.wav", 0.7 * (sine(196)(t(0.32)) + sine(208)(t(0.32))) *
     env_decay(int(SR * 0.32), 5.0))
save("gate_ok.wav", pluck([523.25, 659.25, 783.99], sec=0.3, gap=0.09))
tt_b = t(0.3)
save("gate_bad.wav", 0.6 * square(140)(tt_b) * env_decay(len(tt_b), 6.0))
tt_r = t(0.9)
save("boss_roar.wav", 0.85 * np.tanh(3.0 * saw(70)(tt_r) *
     (1 + 0.5 * sine(6)(tt_r))) * env_decay(len(tt_r), 1.6))
save("lum.wav", pluck([880, 1318.5], sec=0.16, gap=0.08))
tt_c = t(0.7)
_save_harp = (pluck([392, 440, 523.25, 587.33], sec=0.35, gap=0.1, gain=0.6))
save("scroll.wav", _save_harp)
tt_d = t(0.55)
save("phase_break.wav", 0.5 * np.clip(blend(sine(1567)(tt_d) *
     env_decay(len(tt_d), 8.0), 1.2 * noise(0.3, lp=0.7)), -1, 1))
save("click.wav", 0.5 * sine(1200)(t(0.06)) * env_decay(int(SR * 0.06), 12.0))
save("victory.wav", pluck([523.25, 659.25, 783.99, 1046.5], sec=0.4, gap=0.14))

# ───────────── موسیقی محیطی (لوپ‌های ۸ ثانیه‌ای کراس‌فید‌شده) ─────────────
L = t(8.0)
pad = (sine(110)(L) + 0.7 * sine(164.81)(L) + 0.6 * sine(220)(L)
       + 0.4 * sine(329.63)(L))
pad *= (1 + 0.35 * sine(0.13)(L))           # نفس کشیدن آهسته
pad = pad * 0.16
pad[-int(SR * 0.5):] *= np.linspace(1, 0, int(SR * 0.5))   # انتهای لوپ نرم
pad[:int(SR * 0.5)] *= np.linspace(0, 1, int(SR * 0.5))
save("ambient_cave.wav", pad)

bass = np.zeros(len(L))
notes_b = [110, 110, 138.59, 164.81, 110, 110, 174.61, 146.83]
step = 8.0 / len(notes_b)
for i, f in enumerate(notes_b):
    k = int(i * step * SR)
    seg = 0.42 * square(f)(t(step)) * env_decay(int(SR * step), 1.8)
    bass[k:k + len(seg)] += seg
pulse = 0.28 * (1 + np.sign(sine(4)(L))) / 1.5
save("boss_theme.wav", np.clip(bass * pulse, -0.9, 0.9))
