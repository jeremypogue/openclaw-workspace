#!/usr/bin/env python3
"""
Atlas Scientific EZO USB Sensor Bridge
Polls Atlas sensors via USB serial and sends to nodejs-poolController

For EZO Complete sensors on USB (9600 baud, ASCII protocol)
"""

import serial
import time
import json
import requests
import sys
from pathlib import Path

# Configuration
SENSORS = {
    'ph': {'port': '/dev/ttyUSB0', 'type': 'pH'},
    'orp': {'port': '/dev/ttyUSB1', 'type': 'ORP'},
    'ec': {'port': '/dev/ttyUSB2', 'type': 'EC'}
}
POOL_CONTROLLER_URL = 'http://10.0.101.253:4200'
POLL_INTERVAL = 30  # seconds

def find_usb_devices():
    """Find all Atlas USB devices"""
    import glob
    devices = glob.glob('/dev/ttyUSB*') + glob.glob('/dev/ttyACM*')
    return devices

def read_atlas_sensor(port, sensor_type):
    """Read value from Atlas EZO sensor via USB serial"""
    try:
        with serial.Serial(port, 9600, timeout=2) as ser:
            # Clear any pending data
            ser.reset_input_buffer()
            ser.reset_output_buffer()
            time.sleep(0.1)
            
            # Send read command
            ser.write(b'R\r')
            time.sleep(0.6)  # EZO sensors need ~600ms for reading
            
            response = ser.readline().decode('ascii').strip()
            
            # Parse response - format: ?R,value or just value
            if response.startswith('?R,'):
                value = response.split(',')[1]
                return float(value) if value.replace('.','').replace('-','').isdigit() else value
            elif response and not response.startswith('?'):
                try:
                    return float(response)
                except ValueError:
                    return response
            else:
                return None
    except Exception as e:
        return None

def send_to_pool_controller(sensor_type, value):
    """Send reading to nodejs-poolController"""
    try:
        # Map to njspc endpoint
        endpoint = f"{POOL_CONTROLLER_URL}/config/chemController"
        
        payload = {
            'type': 'REM',
            'id': 1,
            sensor_type.lower(): value
        }
        
        response = requests.put(endpoint, json=payload, timeout=5)
        return response.status_code == 200
    except Exception as e:
        return False

def main():
    print("Atlas USB Sensor Bridge starting...")
    
    devices = find_usb_devices()
    if not devices:
        print("No USB serial devices found!")
        print("Check: ls /dev/ttyUSB* /dev/ttyACM*")
        sys.exit(1)
    
    print(f"Found USB devices: {devices}")
    
    while True:
        for sensor_name, config in SENSORS.items():
            value = read_atlas_sensor(config['port'], config['type'])
            
            if value is not None:
                print(f"[{config['type']}] {value}")
                send_to_pool_controller(sensor_name, value)
            else:
                print(f"[{config['type']}] Failed to read")
        
        time.sleep(POLL_INTERVAL)

if __name__ == '__main__':
    main()