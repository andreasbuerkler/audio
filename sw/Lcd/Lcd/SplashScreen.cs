using System;

namespace Lcd
{
    class SplashScreen
    {
        public SplashScreen(Monitor monitorInst)
        {
            _monitor = monitorInst;
        }

        public void Get(Framebuffer frameBuffer)
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
            float totalPower = (ch0Power + ch1Power + ch2Power) / 1000;
            string totalPowerString = String.Format("{0,6:0.00}w", totalPower);

            frameBuffer.SetText(totalPowerString, 5, 29);
            frameBuffer.SetText(ch0VoltageString, 5, 1);
            frameBuffer.SetText(ch0CurrentString, 7, 1);
            frameBuffer.SetText(ch1VoltageString, 9, 5);
            frameBuffer.SetText(ch1CurrentString, 11, 5);
            frameBuffer.SetText(ch2VoltageString, 9, 25);
            frameBuffer.SetText(ch2CurrentString, 11, 25);
            frameBuffer.SetText("waiting ...", 5, 14);
            _waitingBar += 50;
            frameBuffer.SetSpeed(_waitingBar % 8000);

            if ((_waitingBar / 1000) % 2 == 0)
            {
                frameBuffer.SetBgColor(0x0D, Colors.ColorIndex.Yellow);
                frameBuffer.SetBgColor(0x0E, Colors.ColorIndex.Blue);
            }
            else
            {
                frameBuffer.SetBgColor(0x0D, Colors.ColorIndex.Blue);
                frameBuffer.SetBgColor(0x0E, Colors.ColorIndex.Yellow);
            }
        }

        private Monitor _monitor;
        private int _waitingBar = 0;
    }
}
