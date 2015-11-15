# PANDA

**P**ersonal
**A**utomated
**N**etworked
**D**rug
**A**ssistant

<img src=/doc/PANDA.png width="300">

PANDA is a smart pillbox that reminds you when to take your medicine! Using the web interface, you can tell PANDA when to remind you. PANDA can take either a list of times or set period between reminders.

Once it is time to take your medication, PANDA will start beeping and light up the indicator next to the medicine you need to take. The only way to quiet PANDA is to open the box, so there is no chance you will forget to take your medicine. Also, PANDA remembers if you took your medicine already. If the light is red, you know you don't need to take the pill again.

# Motivation

Regardless of how careful doctors and pharmacists are at prescribing medicine, the responsibility of actually taking the correct medication at the right times still falls on the patient. Despite how important it is to take the right medication at the right time, pharmacists still have to give instructions verbally to patients and these instructions grow increasingly complex as the number of prescriptions increase. Using PANDA, patients can bring a pharmacist home with them. Pharmacists are able to fill out an online with drug administration instructions and that information is then transmitted via Wi-Fi using Electric Imp to PANDA, which is fitted with two LEDs per prescription. One that lights up green which means take and one that lights up red that means do not take. The PANDA beeps when it’s time to take medicine and the beeping only stops when a light sensor detects that PANDA has been opened and thus medication has been taken. Because the PANDA is battery-operated, it can be put in the most convenient location. PANDA is great for patients who have to take medicine daily, from those taking Lipitor after a heart attack, to women on birth control.

# Hardware

<img src=/doc/Schematic.png width="480">

PANDA is built around the Electric Imp platform. PANDA uses a CdS photocell to detect if the lid is open or not based on the brightness change. This photocell is read using an analog input on the Electric Imp using a 1kΩ resistor on the high side in a voltage divider configuration. There are two red/green LED's (Newark 20K5342) indicating which medicine to take. These LED's are bidirectional, so they emit green light when biased in one direction and red light when biased in the other. The LED's are controlled using two pairs of digital output pins. The final pin is used to drive the piezo speaker (Sparkfun COM-07950) using a fixed frequency PWM signal. PANDA is powered by a 4xAA battery holder hooked into the battery input (P+/-) pads on the Electric Imp.

# Software

PANDA can be configured using a [web interface](http://ag6gr.github.io/PANDA/), created using Bootstrap and Javascript. The web interface communicates with the Electric Imp servers using standard http requests. Timekeeping and alert triggering are managed by polling loops in the server side of the Electric Imp. The device is notified of alerts using the standard message passing functionality built into the Electric Imp platform. Source code is available on [Github](https://github.com/AG6GR/PANDA).
