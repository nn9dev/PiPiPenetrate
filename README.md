# PiPiPenetrate
Locally grown, ethically sourced.

#### Why do we need another one of these?
Other current solutions were too messy. 

The script is designed with the aim of avoiding prebuilts. It's also incredibly simple to use and re-deploy.
This gnarly one-liner can be used to run the script on your newly-flashed Pi. SSH in and paste.
```bash
sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/nn9dev/PiPiPenetrate/main/PiPiPenetrate.sh)"
```
Note: The script assumes a Debian/Raspbian/Ubuntu-like environment (apt).

----------

### What does your do that others don't?
- Avoids prebuilts where possible
- Increased success rate via _NUM options using [a PPPwn_cpp fork.](https://github.com/nn9dev/PPPwn_cpp)
- Ability to deploy without interaction from user
- idk that's about it

## The Walkthrough
I won't go too in-depth, since most of the script is explained by looking AT the script.

If this is your first time

### 0. Flash your Pi. Copy payload.
You can find instructions on flashing your Pi [here.](https://www.raspberrypi.com/documentation/computers/getting-started.html#raspberry-pi-imager)

My setup uses a Raspberry Pi 4B running Raspbian Lite. You'll need a way to get your Pi's IP Address after setup. You can either log in to your router or get out the 'ol mouse and keyboard. Nonetheless, make sure to write down the USERNAME and IP ADDRESS of your Pi. Or just remember it. Don't let me tell you what to do.

Prep a flash drive in exFAT format. If you're using goldhen, place [goldhen.bin](https://github.com/GoldHEN/GoldHEN/releases) onto the root of the USB. If you're using ps4-hen-vtx, place the appropriate [ps4-hen-FW-PPPwn-vtx.bin](https://github.com/EchoStretch/ps4-hen-vtx/releases) onto the root of the USB as `payload.bin`.

Plug the USB into the PS4.

### 1. Run The script.
Get the script onto your Pi. You can use the gnarly one-liner above if it's already connected to the internet and the script wil run.

Alternatively, you can put the script in the boot partition of the drive via Windows.
If you copy via Windows, you can run the script by first making it executable:
```bash
sudo chmod +x /boot/firmware/PiPiPenetrate.sh
```
And then running it:
```bash
sudo /boot/firmware/PiPiPenetrate.sh
```

### 2. Answer the questions.
Questions will be proposed to you. Answer them with the whole truth and nothing but the truth.
If you're using a pi with an external dongle, be sure to choose the option to change your network interface.

#### On _NUM options...
With help from [Borris-ta](https://github.com/Borris-ta) and [DrYenyen](https://github.com/DrYenyen/), it has been found that changing some of the variables related to the PPPwn exploit can greatly increase success. For the purposes of this note, all values will be in ***HEX.*** If you'd like to quickly test values, you can use [PPwn-Tinker-GUI](https://github.com/DrYenyen/PPPwn-Tinker-GUI) on Windows or the [PPPwn_cpp CLI](https://github.com/nn9dev/PPPwn_cpp) directly on Linux.

SPRAY_NUM is 0x1000 in the original exploit. Brief testing shows that increasing this by steps of 0x50 up to around 0x1500 results in better reliability.

PIN_NUM is 0x1000 in the original exploit. Its purpose is the time to wait on a CPU before proceeding with the exploit. Brief testing has shown this doesn't affect too much, so it's fine to leave this at default.

CORRUPT_NUM is 0x1 in the original exploit. CORRUPT_NUM is the amout of malicious packets sent to the PS4. Breif testing shows increasing this results in much better reliability. Reccomended values are 0x1 0x2, 0x4, 0x6, 0x8, 0x10, 0x14, 0x20, 0x30, 0x40. Values too high may result in a crash.

#### "The Strat"
During "Brief Testing", a spray value ~1/4 of the default value was accidentally tested. For whatever reason, this increased reliability by a statistically anomalous amount. So... if you use a spray value of 0x44C (decimal 1100... note the lack of an 0x...) and a higher than normal corrupt value (like 0x6), it's just... better...? I feel like this should have consequences, but I haven't found any! So try it out!

### 3. Wait.
After answering the questions, go get a snack. It'll take a bit to build everything. Setup takes ~5 minutes on a Raspberry Pi 4B. After it's all done, the Pi will reboot.

### 4. ???
Set up the PPPoE interface on your PS4.

Navigate to Settings -> Network -> Set Up Internet Connection
Then...

Use a LAN Cable -> Custom -> PPPoE. User ID and Password should both be ***ppp***

Automatic DNS, Automatic MTU, Do Not Use for Proxy Server, then Test Internet Connection. The exploit will start.

### 5. Profit
When you see "PPPwned" appear on your screen, congrats! Your PS4 has been jailbroken.

---------

## Using the script without interaction
At the top of the script, every variable is described. In the case you're feeling particularly cold towards your Pi, you can set all the variables yourself so you don't have to interact with anything. Set the `SKIP_OPTIONS` variable to `yes` to skip the questions.

## To-Do list
- [ ] Internet Forwarding (use Pi internet as PS4 internet)
- [ ] Detect if goldhen is running so rest doesn't trigger a re-pwn
- [ ] Use Pi as USB device?
