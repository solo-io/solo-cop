import http from 'k6/http';
import { sleep, check } from 'k6';

export let options = {
  insecureSkipTLSVerify: true,
  discardResponseBodies: true,

  scenarios: {
    one: {
      executor: 'constant-vus',
      vus: 1200,
      duration: '10m',
      exec: 'all', // the function this scenario will execute
    },
    two: {
      executor: 'constant-vus',
      vus: 1200,
      duration: '10m',
      exec: 'onlyextauth', // the function this scenario will execute
      startTime: '12m',  // duration + gracefulStop of the above
    },
    three: {
      executor: 'constant-vus',
      vus: 1200,
      duration: '10m',
      exec: 'onlywaf', // the function this scenario will execute
      startTime: '24m',  // duration + gracefulStop of the above
    },
    four: {
      executor: 'constant-vus',
      vus: 1200,
      duration: '10m',
      exec: 'nofilters', // the function this scenario will execute
      startTime: '36m',  // duration + gracefulStop of the above
    },
    five: {
      executor: 'constant-vus',
      vus: 1200,
      duration: '10m',
      exec: 'direct', // the function this scenario will execute
      startTime: '48m',  // duration + gracefulStop of the above
    },
  },
};

export function direct() {
  const params = {
    tags: { name: 'singleMetricDynamicURL' },
  };
  const res = http.get(`http://echoenv.workspace-1.svc.cluster.local:8000/`, params);//direct
  check(res, {
    'is status 2xx': (r) => parseInt(r.status / 100) === 2 ,
    'is status 4xx': (r) => parseInt(r.status / 100) === 4 ,
    'is status 5xx': (r) => parseInt(r.status / 100) === 5 ,
    'is status else': (r) => parseInt(r.status / 100) !== 2 && parseInt(r.status / 100) !== 4 && parseInt(r.status / 100) !== 5,
  });
  //sleep(1);
}

export function nofilters() {
  const params = {
    tags: { name: 'singleMetricDynamicURL' },
  };
  const rnd2 = 1 + Math.floor(Math.random() * 50);
  const res = http.get(`https://workspace-1-domain-1.com/get/${rnd2}`, params);//no filters
  check(res, {
    'is status 2xx': (r) => parseInt(r.status / 100) === 2 ,
    'is status 4xx': (r) => parseInt(r.status / 100) === 4 ,
    'is status 5xx': (r) => parseInt(r.status / 100) === 5 ,
    'is status else': (r) => parseInt(r.status / 100) !== 2 && parseInt(r.status / 100) !== 4 && parseInt(r.status / 100) !== 5,
  });
  //sleep(1);
}

export function onlywaf() {
  const params = {
    tags: { name: 'singleMetricDynamicURL' },
  };
  const rnd2 = 1 + Math.floor(Math.random() * 50);
  const res = http.get(`https://workspace-2-domain-1.com/get/${rnd2}`, params);//waf
  check(res, {
    'is status 2xx': (r) => parseInt(r.status / 100) === 2 ,
    'is status 4xx': (r) => parseInt(r.status / 100) === 4 ,
    'is status 5xx': (r) => parseInt(r.status / 100) === 5 ,
    'is status else': (r) => parseInt(r.status / 100) !== 2 && parseInt(r.status / 100) !== 4 && parseInt(r.status / 100) !== 5,
  });
  //sleep(1);
}

export function onlyextauth() {
  const params = {
    headers: {
      'api-key': 'N2YwMDIxZTEtNGUzNS1jNzgzLTRkYjAtYjE2YzRkZGVmNjcy',
    },
    tags: { name: 'singleMetricDynamicURL' },
  };
  const rnd2 = 1 + Math.floor(Math.random() * 50);
  const res = http.get(`https://workspace-3-domain-1.com/get/${rnd2}`, params);//extauth
  check(res, {
    'is status 2xx': (r) => parseInt(r.status / 100) === 2 ,
    'is status 4xx': (r) => parseInt(r.status / 100) === 4 ,
    'is status 5xx': (r) => parseInt(r.status / 100) === 5 ,
    'is status else': (r) => parseInt(r.status / 100) !== 2 && parseInt(r.status / 100) !== 4 && parseInt(r.status / 100) !== 5,
  });
  //sleep(1);
}

export function all() {
  const params = {
    headers: {
      'api-key': 'N2YwMDIxZTEtNGUzNS1jNzgzLTRkYjAtYjE2YzRkZGVmNjcy',
    },
    tags: { name: 'singleMetricDynamicURL' },
  };
  const rnd2 = 1 + Math.floor(Math.random() * 50);
  const res = http.get(`https://workspace-4-domain-1.com/get/${rnd2}`, params);//waf + extauth
  check(res, {
    'is status 2xx': (r) => parseInt(r.status / 100) === 2 ,
    'is status 4xx': (r) => parseInt(r.status / 100) === 4 ,
    'is status 5xx': (r) => parseInt(r.status / 100) === 5 ,
    'is status else': (r) => parseInt(r.status / 100) !== 2 && parseInt(r.status / 100) !== 4 && parseInt(r.status / 100) !== 5,
  });
  //sleep(1);
}
