using UnityEngine;

public enum Season
{
    Spring,
    Summer,
    Autumn,
    Winter
}

public class SeasonColouring : MonoBehaviour
{
    [SerializeField] private MeshRenderer _meshRenderer;
    [SerializeField] private Season _season;
    [SerializeField] private SeasonData _springSeasonData;
    [SerializeField] private SeasonData _summerSeasonData;
    [SerializeField] private SeasonData _autumnSeasonData;
    [SerializeField] private SeasonData _winterSeasonData;
    [SerializeField] private Light _mainLight;
    private Material _material;

    private void Start() => ReloadSeasonData();

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.LeftArrow))
        {
            if ((int)_season == 0) _season = (Season)4;
            _season = (Season)((int)(_season - 1) % 4);
            ReloadSeasonData();
        }

        if (Input.GetKeyDown(KeyCode.RightArrow))
        {
            _season = (Season)((int)(_season + 1) % 4);
            ReloadSeasonData();
        }
    }

    private SeasonData SelectSeasonData()
    {
        return _season switch
        {
            Season.Spring => _springSeasonData,
            Season.Summer => _summerSeasonData,
            Season.Autumn => _autumnSeasonData,
            Season.Winter => _winterSeasonData,
            _ => null
        };
    }

    private void ReloadSeasonData()
    {
        SeasonData seasonData = SelectSeasonData();
        _material = _meshRenderer.material;
        _material.SetColor("_TipColor", seasonData.TipColor);
        _material.SetColor("_BaseColor", seasonData.BaseColor);

        _mainLight.color = seasonData.LightColor;
        _mainLight.intensity = seasonData.LightIntensity;
    }
}
