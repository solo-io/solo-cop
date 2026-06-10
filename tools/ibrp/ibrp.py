import argparse
import os.path
import yaml


def write_to_file(custom_resource):
    if not os.path.exists('./crs'):
        os.mkdir('./crs')
    kind = custom_resource.get('kind')
    kind_dir = './crs/' + kind
    if not os.path.exists(kind_dir):
        os.mkdir(kind_dir)
    metadata = custom_resource.get('metadata')
    name = metadata.get('name')
    output_filename = kind_dir + '/' + name + '.yaml'
    with open(output_filename, 'w') as yaml_file:
        print('Creating ' + output_filename)
        yaml.dump(custom_resource, yaml_file)


def parse_crs(yaml_input):
    print('Parsing ' + yaml_input)
    print('WARNING: If your file is really big, this may take a minute!')
    with open(yaml_input, 'r') as file:
        crs = yaml.safe_load(file)
        items = crs.get('items')
        for cr in items:
            write_to_file(cr)


def parse_nodes(node_input):
    print('Parsing ' + node_input)
    file = open(node_input, 'r')
    lines = file.readlines()
    capacity = False

    for line in lines:
        line = line.lstrip()
        if line.startswith("name: "):
            name = line.split(' ', 1)[1].strip()
        if line.startswith("capacity"):
            capacity = True
        if capacity and line.startswith('cpu:'):
            cpu = line.split('cpu:', 1)[1].strip()
        if capacity and line.startswith('memory:'):
            memory = line.split('memory:', 1)[1].strip()
            print(name + ',' + memory + ',' + cpu)
            capacity = False


def parse_proxies(proxies_input):
    print('Parsing ' + proxies_input)
    file = open(proxies_input, 'r')
    lines = file.readlines()
    pod = False
    proxy = False
    resources = False
    requests = False
    limits = False
    name_captured = False
    namespace_captured = False

    for line in lines:
        line = line.lstrip()
        if line.startswith("kind: Pod"):
            pod = True
        if pod and line.startswith("name: istio-proxy"):
            proxy = True
        if pod and not name_captured and line.startswith("name:"):
            name = line.split('name:', 1)[1].strip()
            name_captured = True
        if not namespace_captured and line.startswith("namespace:"):
            namespace = line.split('namespace:', 1)[1].strip()
            namespace_captured = True
        if proxy and line.startswith("resources"):
            resources = True
        if proxy and line.startswith("limits:"):
            limits = True
            requests = False
        if resources and limits and line.startswith('cpu:'):
            cpu_limits = line.split('cpu:', 1)[1].strip()
        if resources and limits and line.startswith('memory:'):
            memory_limits = line.split('memory:', 1)[1].strip()
        if line.startswith("requests:"):
            requests = True
            limits = False
        if resources and requests and line.startswith('cpu:'):
            cpu_requests = line.split('cpu:', 1)[1].strip()
            continue
        if resources and requests and line.startswith('memory:'):
            memory_requests = line.split('memory:', 1)[1].strip()
            print(name + ',' + namespace + ',' + cpu_limits + ',' + memory_limits + ',' + cpu_requests + ',' + memory_requests)
            pod = False
            proxy = False
            resources = False
            requests = False
            limits = False
            name_captured = False
            namespace_captured = False


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("op", help="Operation you want.  One of crparse, nodeparse or proxyparse")
    parser.add_argument("file", help="File containing information that you want to parse")
    args = parser.parse_args()
    if args.op == 'crparse':
        parse_crs(args.file)
    elif args.op == 'nodeparse':
        parse_nodes(args.file)
    elif args.op == 'proxyparse':
        parse_proxies(args.file)
    else:
        print('Sorry, you need to ask for either crparse, nodeparse or proxyparse.')

