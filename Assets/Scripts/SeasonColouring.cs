using System;
using UnityEngine;

namespace UnityGrassShader
{
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
        [SerializeField] private SeasonData _defaultSeasonData;
        [SerializeField] private bool _useDefaultSeasonData = false;

        [Header("SeasonData")]
        [SerializeField] private Season _season;
        [SerializeField] private SeasonData _springSeasonData;
        [SerializeField] private SeasonData _summerSeasonData;
        [SerializeField] private SeasonData _autumnSeasonData;
        [SerializeField] private SeasonData _winterSeasonData;

        [Header("Scene Elements")]
        [SerializeField] private Light _mainLight;
        [SerializeField] private ParticleSystem _leavesParticles;
        [SerializeField] private ParticleSystem _firefliesParticles;
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

        public void ChangeSeason(string newSeason)
        {
            Season season = (Season)Enum.Parse(typeof(Season), newSeason);
            ChangeSeason(season);
        }

        public void ChangeSeason(Season season)
        {
            _season = season;
            SelectSeasonData();
            ReloadSeasonData();
        }

        private SeasonData SelectSeasonData()
        {
            if (_useDefaultSeasonData) return _defaultSeasonData;

            return _season switch
            {
                Season.Spring => _springSeasonData,
                Season.Summer => _summerSeasonData,
                Season.Autumn => _autumnSeasonData,
                Season.Winter => _winterSeasonData,
                _ => _defaultSeasonData
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

            var leavesMain = _leavesParticles.main;
            leavesMain.startColor = seasonData.LeavesColor;

            var firefliesColor = _firefliesParticles.colorOverLifetime;
            firefliesColor.color = seasonData.FirefliesColorOverLifetime;
            var firefliesMaterial = _firefliesParticles.GetComponent<ParticleSystemRenderer>().material;
            firefliesMaterial.SetColor("_EmissionColor", seasonData.FirefliesStartColor * Mathf.Pow(2, 5));
        }
    }
}
