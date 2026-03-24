"""
download_aist.py — Download AIST++ motion data and music.

AIST++ provides:
  - keypoints3d/  : COCO 17-joint 3D keypoints per dance sequence (.npy)
  - wav/          : Paired music tracks (.wav)
  - splits/       : Train/val/test splits

Usage:
  python download_aist.py           # downloads keypoints3d + music
  python download_aist.py --check   # just check what's downloaded
"""

import os
import sys
import urllib.request
import zipfile
import shutil
from pathlib import Path

DATA_DIR = Path(__file__).parent / "data"

# AIST++ download URLs (from Google's official release)
# Keypoints: https://google.github.io/aistplusplus_dataset/download.html
URLS = {
    "keypoints3d": "https://storage.googleapis.com/aist_plusplus_public/20210308/keypoints3d.zip",
    "wav": "https://storage.googleapis.com/aist_plusplus_public/20210308/all_musics.zip",
    "splits": "https://storage.googleapis.com/aist_plusplus_public/20210308/splits.zip",
}

# Sequence naming convention:
# gBR_sBM_cAll_d04_mBR0_ch01
#  g=genre, s=situation, c=camera, d=dancer, m=music, ch=choreography
#
# Genre codes: BR=Break, PO=Pop, LO=Lock, MH=Middle Hip-hop,
#              LH=LA Hip-hop, HO=House, WA=Waack, KR=Krump,
#              JS=Street Jazz, JB=Ballet Jazz

GENRE_MAP = {
    "gBR": "break",
    "gPO": "pop",
    "gLO": "lock",
    "gMH": "middle_hiphop",
    "gLH": "la_hiphop",
    "gHO": "house",
    "gWA": "waack",
    "gKR": "krump",
    "gJS": "street_jazz",
    "gJB": "ballet_jazz",
}


def download_file(url, dest):
    """Download with progress bar."""
    if dest.exists():
        print(f"  Already exists: {dest.name}")
        return

    print(f"  Downloading {dest.name}...")

    def reporthook(count, block_size, total_size):
        pct = count * block_size * 100 // total_size if total_size > 0 else 0
        print(f"\r  {pct}%", end="", flush=True)

    urllib.request.urlretrieve(url, str(dest), reporthook=reporthook)
    print(f"\r  Done: {dest.name}")


def extract_zip(zip_path, extract_to):
    """Extract zip file."""
    print(f"  Extracting {zip_path.name}...")
    with zipfile.ZipFile(str(zip_path), "r") as zf:
        zf.extractall(str(extract_to))
    print(f"  Extracted to {extract_to}")


def download_all():
    """Download all AIST++ data."""
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    zips_dir = DATA_DIR / "zips"
    zips_dir.mkdir(exist_ok=True)

    for name, url in URLS.items():
        zip_path = zips_dir / f"{name}.zip"
        download_file(url, zip_path)

        # Extract if not already done
        extract_marker = DATA_DIR / f".{name}_extracted"
        if not extract_marker.exists():
            extract_zip(zip_path, DATA_DIR)
            extract_marker.touch()


def check_data():
    """Report what data is available."""
    print(f"\nData directory: {DATA_DIR}")

    # Check keypoints
    kp_dir = DATA_DIR / "keypoints3d"
    if kp_dir.exists():
        files = list(kp_dir.glob("*.npy"))
        print(f"  Keypoints3D: {len(files)} sequences")

        # Count by genre
        genre_counts = {}
        for f in files:
            prefix = f.stem[:3]  # e.g. "gBR"
            genre = GENRE_MAP.get(prefix, prefix)
            genre_counts[genre] = genre_counts.get(genre, 0) + 1
        for genre, count in sorted(genre_counts.items()):
            print(f"    {genre}: {count}")
    else:
        print("  Keypoints3D: NOT DOWNLOADED")

    # Check music
    wav_dir = DATA_DIR / "all_musics"
    if wav_dir.exists():
        files = list(wav_dir.glob("*.wav"))
        print(f"  Music tracks: {len(files)}")
    else:
        print("  Music tracks: NOT DOWNLOADED")

    # Check splits
    splits_dir = DATA_DIR / "splits"
    if splits_dir.exists():
        files = list(splits_dir.glob("*.txt"))
        print(f"  Split files: {len(files)}")
        for f in sorted(files):
            with open(f) as fh:
                lines = fh.readlines()
            print(f"    {f.name}: {len(lines)} sequences")
    else:
        print("  Splits: NOT DOWNLOADED")


def get_music_id(seq_name):
    """Extract music ID from sequence name.

    e.g. 'gBR_sBM_cAll_d04_mBR0_ch01' → 'mBR0'
    The music file is named like 'mBR0.wav'
    """
    parts = seq_name.split("_")
    for p in parts:
        if p.startswith("m"):
            return p
    return None


if __name__ == "__main__":
    if "--check" in sys.argv:
        check_data()
    else:
        download_all()
        check_data()
