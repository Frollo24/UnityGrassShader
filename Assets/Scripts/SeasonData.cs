using UnityEngine;

[CreateAssetMenu(menuName = "SeasonData", fileName = "NewSeasonData")]
public class SeasonData : ScriptableObject
{
    public Color TipColor = new Color(0.5792569f, 0.846f, 0.3297231f, 1f);
    public Color BaseColor = new Color(0.06129726f, 0.378f, 0.07151345f, 1f);
    public Color LightColor = new Color(1f, 0.9568627f, 0.8392157f, 1f);
    public float LightIntensity = 2f;

    public Color LeavesColor = new Color(0.2509804f, 0.8823529f, 0.1686275f, 1f);
    public Color FirefliesStartColor = new Color(1f, 0.8313726f, 0.2862745f, 1f);
    public Color FirefliesEndColor = new Color(0.9921569f, 0.8078431f, 0.02745098f, 1f);
    public float FirefliesIntensity = 4f;

    public ParticleSystem.MinMaxGradient FirefliesColorOverLifetime
    {
        get { return new ParticleSystem.MinMaxGradient(FirefliesStartColor, FirefliesEndColor); }
    }
}
