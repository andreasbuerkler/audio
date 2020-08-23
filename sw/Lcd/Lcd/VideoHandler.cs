using System;
using System.Timers;
using System.Text;

namespace Lcd
{
    class VideoHandler
    {
        public VideoHandler(Eth ethInst)
        {
            _enable = false;
            _ethernet = ethInst;
            _frameBuffer = new Framebuffer();
            _acc = new Acc();
            _updateTimer = new System.Timers.Timer(16.666);
            _updateTimer.Elapsed += TimerElapsed;
            _updateTimer.AutoReset = true;
            _updateTimer.Enabled = true;
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
                if (_acc.TryOpen())
                {
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

            // TODO: unused

            // pInfo.tcInAction
            // pInfo.absInAction

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
                string bestSecString = String.Format("{0,0:" +
                    "" +
                    "00}", bestSec);
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

            string biasString = String.Format("bias   {0,2}%", (int)(pInfo.brakeBias*100)-14); // TODO: offset only valid for Lexus RFC
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
        private bool _enable = false;
        private bool _lock = false;
    }
}
