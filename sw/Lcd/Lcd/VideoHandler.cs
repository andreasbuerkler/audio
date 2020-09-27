using System;
using System.Timers;
using System.Text;

namespace Lcd
{
    class VideoHandler
    {
        public VideoHandler(Eth ethInst, Monitor monitorInst)
        {
            _enable = false;
            _ethernet = ethInst;
            _frameBuffer = new Framebuffer();
            _acc = new Acc();
            _monitor = monitorInst;
            _updateTimer = new System.Timers.Timer(16.666);
            _updateTimer.Elapsed += TimerElapsed;
            _updateTimer.AutoReset = true;
            _updateTimer.Enabled = true;
        }

        private void ShowSplashScreen()
        {
            Monitor.MonitorStatus status;

            _monitor.GetStatus(out status);
            string ch0VoltageString = String.Format("0: {0,6:0.00}v", status.ch0.voltage);
            string ch0CurrentString = String.Format("0: {0,6:0.00}mA", status.ch0.current);
            float ch0Power = status.ch0.voltage * status.ch0.current;
            string ch1VoltageString = String.Format("1: {0,6:0.00}v", status.ch1.voltage);
            string ch1CurrentString = String.Format("1: {0,6:0.00}mA", status.ch1.current);
            float ch1Power = status.ch1.voltage * status.ch1.current;
            string ch2VoltageString = String.Format("2: {0,6:0.00}v", status.ch2.voltage);
            string ch2CurrentString = String.Format("2: {0,6:0.00}mA", status.ch2.current);
            float ch2Power = status.ch2.voltage * status.ch2.current;
            float totalPower = (ch0Power + ch1Power + ch2Power)/1000;
            string totalPowerString = String.Format("{0,6:0.00}w", totalPower);

            _frameBuffer.SetText(totalPowerString, 5, 29);
            _frameBuffer.SetText(ch0VoltageString, 5, 1);
            _frameBuffer.SetText(ch0CurrentString, 7, 1);
            _frameBuffer.SetText(ch1VoltageString, 9, 5);
            _frameBuffer.SetText(ch1CurrentString, 11, 5);
            _frameBuffer.SetText(ch2VoltageString, 9, 25);
            _frameBuffer.SetText(ch2CurrentString, 11, 25);
            _frameBuffer.SetText("waiting ...", 5, 14);
            _waitingBar += 50;
            _frameBuffer.SetSpeed(_waitingBar%8000);

            if ((_waitingBar / 1000) % 2 == 0)
            {
                _frameBuffer.SetBgColor(0x0D, Colors.ColorIndex.Yellow);
                _frameBuffer.SetBgColor(0x0E, Colors.ColorIndex.Blue);
            }
            else
            {
                _frameBuffer.SetBgColor(0x0D, Colors.ColorIndex.Blue);
                _frameBuffer.SetBgColor(0x0E, Colors.ColorIndex.Yellow);
            }

            _frameBuffer.UpdateBuffer(_ethernet);
        }
        private void TimerElapsed(Object source, ElapsedEventArgs e)
        {
            if (_lock)
            {
                return;
            }
            _lock = true;

            if (!_enable)
            {
                ShowSplashScreen();

                if (_acc.TryOpen())
                {
                    _frameBuffer.SetBgColor(0x0D, Colors.ColorIndex.Blue);
                    _frameBuffer.SetBgColor(0x0E, Colors.ColorIndex.Blue);
                    _enable = true;
                }
                else
                {
                    _lock = false;
                    return;
                }
            }

            Acc.PhysikInfo pInfo;
            Acc.GraphicInfo gInfo;
            if (!_acc.GetData(out pInfo, out gInfo))
            {
                _enable = false;
                _lock = false;
                return;
            }

            // Change background color to yellow if TC is active
            if (pInfo.tcInAction != 0)
            {
                _tcHoldCounter = _holdTime;
            }
            else
            {
                if (_tcHoldCounter > 0)
                {
                    _tcHoldCounter--;
                }
            }
            if (_tcHoldCounter == _holdTime - 1)
            {
                _frameBuffer.SetBgColor(0x0D, Colors.ColorIndex.Yellow);
            }
            if (_tcHoldCounter == 1)
            {
                _frameBuffer.SetBgColor(0x0D, Colors.ColorIndex.Blue);
            }

            // Change background color to yellow if ABS is active
            if (pInfo.absInAction != 0)
            {
                _absHoldCounter = _holdTime;
            }
            else
            {
                if (_absHoldCounter > 0)
                {
                    _absHoldCounter--;
                }
            }
            if (_absHoldCounter == _holdTime - 1)
            {
                _frameBuffer.SetBgColor(0x0E, Colors.ColorIndex.Yellow);
            }
            if (_absHoldCounter == 1)
            {
                _frameBuffer.SetBgColor(0x0E, Colors.ColorIndex.Blue);
            }

            // TODO: unused values
            // -------------------
            // gInfo.iLastTime
            // gInfo.isDeltaPositive
            // gInfo.iDeltaLapTime
            // gInfo.isValidLap

            // pInfo.carDamage[0]);
            // pInfo.carDamage[1]);
            // pInfo.carDamage[2]);
            // pInfo.carDamage[3]);
            // pInfo.carDamage[4]);

            string speedString = String.Format("{0,3} kph", (int)Math.Round(pInfo.speedKmh));
            _frameBuffer.SetText(speedString, 5, 4);

            string lapString = String.Format("{0,2} lap", gInfo.numberOfLaps);
            _frameBuffer.SetText(lapString, 7, 5);

            string fuelString = String.Format("{0,5:F2} l", pInfo.fuel);
            _frameBuffer.SetText(fuelString, 5, 31);

            string rpmString = String.Format("{0,4} rpm", pInfo.rpm);
            _frameBuffer.SetText(rpmString, 7, 31);

            int timeMs = gInfo.iCurrentTime % 1000;
            int timeSec = (gInfo.iCurrentTime / 1000) % 60;
            int timeMin = gInfo.iCurrentTime / 60000;
            string timeMsString = String.Format("{0,0:000}", timeMs);
            string timeSecString = String.Format("{0,0:00}", timeSec);
            string timeMinString = String.Format("{0,2}", timeMin);
            string timeString = "time " + timeMinString + ":" + timeSecString + ":" + timeMsString;
            _frameBuffer.SetText(timeString, 5, 13);

            string bestString;
            if (gInfo.iBestTime > (60 * 60 * 1000))
            {
                bestString = "best --:--:---";
            }
            else
            {
                int bestMs = gInfo.iBestTime % 1000;
                int bestSec = (gInfo.iBestTime / 1000) % 60;
                int bestMin = gInfo.iBestTime / 60000;
                string bestMsString = String.Format("{0,0:000}", bestMs);
                string bestSecString = String.Format("{0,0:00}", bestSec);
                string bestMinString = String.Format("{0,2}", bestMin);
                bestString = "best " + bestMinString + ":" + bestSecString + ":" + bestMsString;
                _frameBuffer.SetText(bestString, 7, 13);

            }
            _frameBuffer.SetText(bestString, 7, 13);

            string posString = String.Format("pos {0,2}", gInfo.position);
            _frameBuffer.SetText(posString, 15, 17);

            string tyre0String = String.Format("{0,2}° {1,2:F1}bar", (int)pInfo.tyreCoreTemp[0], UnitConverter.PsiToBar(pInfo.wheelPressure[0]));
            string tyre1String = String.Format("{0,2}° {1,2:F1}bar", (int)pInfo.tyreCoreTemp[1], UnitConverter.PsiToBar(pInfo.wheelPressure[1]));
            string tyre2String = String.Format("{0,2}° {1,2:F1}bar", (int)pInfo.tyreCoreTemp[2], UnitConverter.PsiToBar(pInfo.wheelPressure[2]));
            string tyre3String = String.Format("{0,2}° {1,2:F1}bar", (int)pInfo.tyreCoreTemp[3], UnitConverter.PsiToBar(pInfo.wheelPressure[3]));
            _frameBuffer.SetText(tyre0String, 9, 5);
            _frameBuffer.SetText(tyre1String, 9, 25);
            _frameBuffer.SetText(tyre2String, 11, 5);
            _frameBuffer.SetText(tyre3String, 11, 25);

            string tcString = String.Format("tc   {0,1}", gInfo.tc);
            _frameBuffer.SetText(tcString, 13, 25);

            string absString = String.Format("abs  {0,1}", gInfo.abs);
            _frameBuffer.SetText(absString, 13, 33);
            int brakeBiasPercent = (pInfo.brakeBias == 0.0) ? 0 : (int)(pInfo.brakeBias * 100) - 14; // TODO: offset only valid for Lexus RFC
            string biasString = String.Format("bias   {0,2}%", brakeBiasPercent);
            _frameBuffer.SetText(biasString, 15, 25);

            string brakeTemp0String = String.Format("{0,3:F1}°", pInfo.brakeTemp[0]);
            string brakeTemp1String = String.Format("{0,3:F1}°", pInfo.brakeTemp[1]);
            string brakeTemp2String = String.Format("{0,3:F1}°", pInfo.brakeTemp[2]);
            string brakeTemp3String = String.Format("{0,3:F1}°", pInfo.brakeTemp[3]);
            _frameBuffer.SetText(brakeTemp0String, 13, 2);
            _frameBuffer.SetText(brakeTemp1String, 13, 10);
            _frameBuffer.SetText(brakeTemp2String, 15, 2);
            _frameBuffer.SetText(brakeTemp3String, 15, 10);

            _frameBuffer.SetText("gear", 13, 18);
            string gearString;
            switch (pInfo.gear)
            {
                case 0:
                    gearString = "R";
                    break;
                case 1:
                    gearString = "N";
                    break;
                default:
                    gearString = (pInfo.gear-1).ToString();
                    break;
            }
            int gear = pInfo.gear - 1;
            _frameBuffer.SetGear(Encoding.UTF8.GetBytes(gearString)[0]);
            _frameBuffer.SetSpeed(pInfo.rpm);
            _frameBuffer.UpdateBuffer(_ethernet);

            _lock = false;
        }

        private Timer _updateTimer;
        private Framebuffer _frameBuffer;
        private Eth _ethernet;
        private Acc _acc;
        private Monitor _monitor;
        private int _waitingBar = 0;
        private const int _holdTime = 30;
        private int _tcHoldCounter = 0;
        private int _absHoldCounter = 0;
        private bool _enable = false;
        private bool _lock = false;
    }
}
