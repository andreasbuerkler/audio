namespace Lcd
{
    static class UnitConverter
    {
        public static float PsiToBar(float psi)
        {
            const float multFactor = 0.0689f;
            return psi * multFactor;
        }
    }
}
