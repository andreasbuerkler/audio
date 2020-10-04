using System;
using System.Text;

namespace Lcd
{
    class DashScreen
    {
        public DashScreen(Acc acc)
        {
            _acc = acc;
        }

        private void SetTc(Framebuffer frameBuffer, float tcActive)
        {
            // Change background color to yellow if TC is active
            if (tcActive != 0.0f)
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
                frameBuffer.SetBgColor(0x0D, Colors.ColorIndex.Yellow);
            }
            if (_tcHoldCounter == 1)
            {
                frameBuffer.SetBgColor(0x0D, Colors.ColorIndex.Blue);
            }
        }

        private void SetAbs(Framebuffer frameBuffer, float absActive)
        {
            // Change background color to yellow if ABS is active
            if (absActive != 0.0f)
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
                frameBuffer.SetBgColor(0x0E, Colors.ColorIndex.Yellow);
            }
            if (_absHoldCounter == 1)
            {
                frameBuffer.SetBgColor(0x0E, Colors.ColorIndex.Blue);
            }
        }

        private void SetGear(Framebuffer frameBuffer, int gear)
        {
            frameBuffer.SetText("gear", 13, 18);
            string gearString;
            switch (gear)
            {
                case 0:
                    gearString = "R";
                    break;
                case 1:
                    gearString = "N";
                    break;
                default:
                    gearString = (gear - 1).ToString();
                    break;
            }
            frameBuffer.SetGear(Encoding.UTF8.GetBytes(gearString)[0]);
        }

        private void SetBestTime(Framebuffer frameBuffer, int bestTime)
        {
            string bestString;
            if (bestTime > (60 * 60 * 1000))
            {
                bestString = "best --:--:---";
            }
            else
            {
                int bestMs = bestTime % 1000;
                int bestSec = (bestTime / 1000) % 60;
                int bestMin = bestTime / 60000;
                string bestMsString = String.Format("{0,0:000}", bestMs);
                string bestSecString = String.Format("{0,0:00}", bestSec);
                string bestMinString = String.Format("{0,2}", bestMin);
                bestString = "best " + bestMinString + ":" + bestSecString + ":" + bestMsString;
                frameBuffer.SetText(bestString, 7, 13);

            }
            frameBuffer.SetText(bestString, 7, 13);
        }

        private void SetCurrentTime(Framebuffer frameBuffer, int currentTime)
        {
            int timeMs = currentTime % 1000;
            int timeSec = (currentTime / 1000) % 60;
            int timeMin = currentTime / 60000;
            string timeMsString = String.Format("{0,0:000}", timeMs);
            string timeSecString = String.Format("{0,0:00}", timeSec);
            string timeMinString = String.Format("{0,2}", timeMin);
            string timeString = "time " + timeMinString + ":" + timeSecString + ":" + timeMsString;
            frameBuffer.SetText(timeString, 5, 13);
        }

        public bool Get(Framebuffer frameBuffer)
        {
            Acc.PhysikInfo pInfo;
            Acc.GraphicInfo gInfo;
            if (!_acc.GetData(out pInfo, out gInfo))
            {
                return false;
            }

            SetTc(frameBuffer, pInfo.tcInAction);
            SetAbs(frameBuffer, pInfo.absInAction);

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
            frameBuffer.SetText(speedString, 5, 4);

            string lapString = String.Format("{0,2} lap", gInfo.numberOfLaps);
            frameBuffer.SetText(lapString, 7, 5);

            string fuelString = String.Format("{0,5:F2} l", pInfo.fuel);
            frameBuffer.SetText(fuelString, 5, 31);

            string rpmString = String.Format("{0,4} rpm", pInfo.rpm);
            frameBuffer.SetText(rpmString, 7, 31);

            SetCurrentTime(frameBuffer, gInfo.iCurrentTime);
            SetBestTime(frameBuffer, gInfo.iBestTime);

            string posString = String.Format("pos {0,2}", gInfo.position);
            frameBuffer.SetText(posString, 15, 17);

            string tyre0String = String.Format("{0,2}° {1,2:F1}bar", (int)pInfo.tyreCoreTemp[0], UnitConverter.PsiToBar(pInfo.wheelPressure[0]));
            string tyre1String = String.Format("{0,2}° {1,2:F1}bar", (int)pInfo.tyreCoreTemp[1], UnitConverter.PsiToBar(pInfo.wheelPressure[1]));
            string tyre2String = String.Format("{0,2}° {1,2:F1}bar", (int)pInfo.tyreCoreTemp[2], UnitConverter.PsiToBar(pInfo.wheelPressure[2]));
            string tyre3String = String.Format("{0,2}° {1,2:F1}bar", (int)pInfo.tyreCoreTemp[3], UnitConverter.PsiToBar(pInfo.wheelPressure[3]));
            frameBuffer.SetText(tyre0String, 9, 5);
            frameBuffer.SetText(tyre1String, 9, 25);
            frameBuffer.SetText(tyre2String, 11, 5);
            frameBuffer.SetText(tyre3String, 11, 25);

            string tcString = String.Format("tc   {0,1}", gInfo.tc);
            frameBuffer.SetText(tcString, 13, 25);

            string absString = String.Format("abs  {0,1}", gInfo.abs);
            frameBuffer.SetText(absString, 13, 33);
            int brakeBiasPercent = (pInfo.brakeBias == 0.0) ? 0 : (int)(pInfo.brakeBias * 100) - 14; // TODO: offset only valid for Lexus RFC
            string biasString = String.Format("bias   {0,2}%", brakeBiasPercent);
            frameBuffer.SetText(biasString, 15, 25);

            string brakeTemp0String = String.Format("{0,3:F1}°", pInfo.brakeTemp[0]);
            string brakeTemp1String = String.Format("{0,3:F1}°", pInfo.brakeTemp[1]);
            string brakeTemp2String = String.Format("{0,3:F1}°", pInfo.brakeTemp[2]);
            string brakeTemp3String = String.Format("{0,3:F1}°", pInfo.brakeTemp[3]);
            frameBuffer.SetText(brakeTemp0String, 13, 2);
            frameBuffer.SetText(brakeTemp1String, 13, 10);
            frameBuffer.SetText(brakeTemp2String, 15, 2);
            frameBuffer.SetText(brakeTemp3String, 15, 10);

            SetGear(frameBuffer, pInfo.gear);

            frameBuffer.SetSpeed(pInfo.rpm);

            return true;
        }

        private Acc _acc;
        private const int _holdTime = 30;
        private int _tcHoldCounter = 0;
        private int _absHoldCounter = 0;
    }
}
