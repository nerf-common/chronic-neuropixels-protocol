# chronic-neuropixels-protocol
(Chronic Neuropixels recordings in mice and rats; Rik van Daal , Cagatay Aydin , Frédéric Michon , Arno Aarts , Michael Kraft , Fabian Kloosterman, Nature Protocols; NP-P200042C, 2021 )

![alt text](fixtures_overview.jpg)

## 3D fixtures
Parts can be printed at [Materalize](https://www.materialise.com/en/manufacturing?gclid=Cj0KCQiA3smABhCjARIsAKtrg6KI-4CloUFmDMtG961YggM_I_BZ4re97FsboS6jPqCWgjePmS5XPqQaAv8xEALw_wcB)

### Data analysis steps
Raw data is filtered and sorted using adapted version of [ecephys_spike_sorting pipeline](https://github.com/jenniferColonell/ecephys_spike_sorting)


__Filtering__: [CatGT](https://billkarsh.github.io/SpikeGLX/#catgt) Version 1.2.6 is used with parameters given below

```python
catGT_cmd_string = '-prb_fld -out_prb_fld -aphipass=300 -aplopass=9000 -gbldmx -gfix=0.4,0.10,0.02'
```

__Sorting__: Kilosort2 is used with default parameters

Number of good units are extracted by using custom written `update_cluster_group.m` function located in [code](https://github.com/nerf-common/chronic-neuropixels-protocol/blob/master/code)

```matlab
% amplitude_cutoff, presence_ratio, isi_viol are generated by using
% https://allensdk.readthedocs.io/en/latest/_static/examples/nb/ecephys_quality_metrics.html
idx = Tmetric.amplitude_cutoff<0.1&... 
    Tmetric.presence_ratio>0.95&...
    Tmetric.isi_viol<0.5&...
    ig; % index for Kilosort2 'good' label after noise removal
```	
__Spike statistics__:

Spike count, amplitude, RMS values are extracted from filtered data by using [neuropixels-evaluation-tools](https://github.com/jenniferColonell/Neuropixels_evaluation_tools) 
