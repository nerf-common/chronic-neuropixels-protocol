# chronic-neuropixels-protocol
(Chronic Neuropixels recordings in mice and rats; Rik van Daal , Cagatay Aydin , Frédéric Michon , Arno Aarts , Michael Kraft , Fabian Kloosterman, Nature Protocols; NP-P200042C, 2021 )

![alt text](fixtures_overview.jpg)

## 3D fixtures
Parts can be printed at [Materalize](https://www.materialise.com/en/manufacturing?gclid=Cj0KCQiA3smABhCjARIsAKtrg6KI-4CloUFmDMtG961YggM_I_BZ4re97FsboS6jPqCWgjePmS5XPqQaAv8xEALw_wcB)

## Data and Custom written Matlab scripts

### Data analysis steps
Raw data is filtered and sorted using adapted version of [ecephys_spike_sorting pipeline](https://github.com/jenniferColonell/ecephys_spike_sorting)


- [CatGT](https://billkarsh.github.io/SpikeGLX/#catgt) Version 1.2.6 is used with parameters given below

```python
catGT_cmd_string = '-prb_fld -out_prb_fld -aphipass=300 -aplopass=9000 -gbldmx -gfix=0.4,0.10,0.02'
```

- Filtered data then sorted by Kilosort2 and to extract spike metrics neuropixels-evaluation-tools is used

- Sorted using Kilosort2

### Matlab

-