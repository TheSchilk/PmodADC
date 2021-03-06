import argparse
from Utils.File_Interface import read_wav
from Utils.Data_Parsing import convert_float_to_uint_audio
from Utils.Interface import play_data_async_packaging
from Utils.resample import resample_audio
import sys
from serial import SerialException

# Setup argument parser
parser = argparse.ArgumentParser(prog='Play.py', description='Play audio through the PmodDAC.\n'
                                                             'By default the audio is resampled to '
                                                             '41kHz.')
parser.add_argument('comport', help='The COM port to which the board is connected.')
parser.add_argument('wavfile', help='The filename of the audio file.')
length_group = parser.add_mutually_exclusive_group(required=False)
length_group.add_argument('-L', action='store_true', help='Play the left audio channel.')
length_group.add_argument('-R', action='store_true', help='Play the right audio channel.')
parser.add_argument('-r', action='store_true', help='Do not re-sample audio to 41kHz.')
# Parse arguments:
args = parser.parse_args()

# Load the audio data:
if args.L or (not args.L and not args.R):
    audio, f_s = read_wav(args.wavfile, channel=0)
else:
    audio, f_s = read_wav(args.wavfile, channel=1)

# Unless disabled, re-sample audio if necessary:
if not args.r:
    if f_s != 41000:
        print('Re-sampling Audio....')
        audio = resample_audio(audio, f_s, 41000)
        f_s = 41000

# Scale the audio data:
audio = convert_float_to_uint_audio(audio)

# Play the audio:
try:
    print('Playing....')
    play_data_async_packaging(args.comport, audio)
except SerialException as e:
    print('Serial Error!')
    print(e)
    sys.exit()
