### Contains a script to get the following files:
- Gloo Mesh input and output snapshot files from a management server pod replica passed as an argument to the script.
- Profile files obtained from /debug/pprof/allocs, /debug/pprof/heap, debug/pprof/profile?seconds=120

### Usage:
```bash
./get-snapshots-and-profiles.sh ${MANAGEMENT_SERVER_POD_NAME}
```

#### Sample Output:
```bash
$ ./get-snapshots-and-profiles.sh gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz

[DEBUG] sleeping for 10 seconds to wait for the port forwarding to start in the background...

[INFO] getting input snapshot from gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz ...


[INFO] getting output snapshot from gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz ...


[INFO] compressing input snapshot...

a input-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz.json

[INFO] compressing output snapshot...

a output-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz.json

[INFO] get /debug/pprof/allocs from gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz

--2023-09-05 18:14:40--  http://localhost:9091/debug/pprof/allocs
Resolving localhost (localhost)... ::1, 127.0.0.1
Connecting to localhost (localhost)|::1|:9091... connected.
HTTP request sent, awaiting response... 200 OK
Length: unspecified [application/octet-stream]
Saving to: ‘allocs-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz’

allocs-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz                   [ <=>                                                                                                                                      ] 258.85K  --.-KB/s    in 0.06s

2023-09-05 18:14:41 (4.20 MB/s) - ‘allocs-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz’ saved [265062]


[INFO] get /debug/pprof/heap from gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz ...

--2023-09-05 18:14:41--  http://localhost:9091/debug/pprof/heap
Resolving localhost (localhost)... ::1, 127.0.0.1
Connecting to localhost (localhost)|::1|:9091... connected.
HTTP request sent, awaiting response... 200 OK
Length: unspecified [application/octet-stream]
Saving to: ‘heap-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz’

heap-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz                     [ <=>                                                                                                                                      ] 259.43K  --.-KB/s    in 0.05s

2023-09-05 18:14:41 (5.45 MB/s) - ‘heap-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz’ saved [265655]


[INFO] get /debug/pprof/profile from gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz for 120 seconds...

--2023-09-05 18:14:41--  http://localhost:9091/debug/pprof/profile?seconds=120
Resolving localhost (localhost)... ::1, 127.0.0.1
Connecting to localhost (localhost)|::1|:9091... connected.
HTTP request sent, awaiting response... 200 OK
Length: unspecified [application/octet-stream]
Saving to: ‘profile-120-sec-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz’

profile-120-sec-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz          [ <=>                                                                                                                                      ]  40.98K  --.-KB/s    in 0.04s

2023-09-05 18:16:41 (935 KB/s) - ‘profile-120-sec-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz’ saved [41966]


[DEBUG] Input Snapshot saved in:       /Users/arka/workspace/solo-cop/tools/snapshot-and-profile-files/input-snapshot-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz.tar.gz
[DEBUG] Output Snapshot saved in:      /Users/arka/workspace/solo-cop/tools/snapshot-and-profile-files/output-snapshot-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz.tar.gz
[DEBUG] /allocs saved in:              /Users/arka/workspace/solo-cop/tools/snapshot-and-profile-files/allocs-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz
[DEBUG] /heap saved in:                /Users/arka/workspace/solo-cop/tools/snapshot-and-profile-files/heap-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz
[DEBUG] /profile?seconds=120 saved in: /Users/arka/workspace/solo-cop/tools/snapshot-and-profile-files/profile-120-sec-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz

a input-snapshot-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz.tar.gz
a output-snapshot-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz.tar.gz
a allocs-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz
a heap-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz
a profile-120-sec-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz

[INFO] All files compressed:     /Users/arka/workspace/solo-cop/tools/snapshot-and-profile-files/all-files-compressed-gloo-mesh-mgmt-server-56b9cdf9bb-r7jmz.tar.gz
```