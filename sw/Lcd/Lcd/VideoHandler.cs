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
            _updateTimer = new System.Timers.Timer(16.666);
            _updateTimer.Elapsed += TimerElapsed;
            _updateTimer.AutoReset = true;
            _updateTimer.Enabled = true;
        }

        public void Enable(bool enable)
        {
            _enable = enable;
        }

        private void TimerElapsed(Object source, ElapsedEventArgs e)
        {
            if (_lock)
            {
                return;
            }
            _lock = true;
            if (_enable)
            {
                _frameBuffer.SetText("time 00:00.000", 5, 13);
                _frameBuffer.SetText("best 00:00.000", 7, 13);
                _frameBuffer.SetText("pos 12", 15, 17);
                _frameBuffer.SetText("96° 2.1bar", 9, 5);
                _frameBuffer.SetText("96° 2.1bar", 11, 5);
                _frameBuffer.SetText("96° 2.1bar", 9, 25);
                _frameBuffer.SetText("96° 2.1bar", 11, 25);
                _frameBuffer.SetText("120 kph", 5, 4);
                _frameBuffer.SetText("23 lap", 7, 5);
                _frameBuffer.SetText("12.3 l", 5, 33);
                string rpmString = String.Format("{0,4} rpm", _rpm);
                _frameBuffer.SetText(rpmString, 7, 31);
                _frameBuffer.SetText("tc   3", 13, 25);
                _frameBuffer.SetText("abs  3", 13, 33);
                _frameBuffer.SetText("bias   63%", 15, 25);
                _frameBuffer.SetText("296°c", 13, 2);
                _frameBuffer.SetText("296°c", 15, 2);
                _frameBuffer.SetText("296°c", 13, 10);
                _frameBuffer.SetText("296°c", 15, 10);
                _frameBuffer.SetText("gear", 13, 18);
                _frameBuffer.SetSpeed(_rpm);
                _frameBuffer.SetGear(Encoding.UTF8.GetBytes("9")[0]);
                _frameBuffer.UpdateBuffer(_ethernet);

                if (_rpm < 8000)
                {
                    _rpm += 100;
                }
                else
                {
                    _rpm = 0;
                }
            }
            _lock = false;
        }

        private Timer _updateTimer;
        private Framebuffer _frameBuffer;
        private Eth _ethernet;
        private bool _enable;
        private bool _lock = false;
        private int _rpm = 0;
    }
}
