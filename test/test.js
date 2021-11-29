#!/usr/bin/env node

'use strict';

/* global describe */
/* global after */
/* global before */
/* global xit */
/* global it */

const execSync = require('child_process').execSync,
    expect = require('expect.js'),
    path = require('path'),
    superagent = require('superagent');

if (!process.env.USERNAME || !process.env.PASSWORD) {
    console.log('USERNAME and PASSWORD env vars need to be set');
    process.exit(1);
}

describe('Application life cycle test', function () {
    this.timeout(0);

    const EXEC_ARGS = { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' };
    const LOCATION = 'test';

    let app;
    const username = process.env.USERNAME;
    const password = process.env.PASSWORD;

    function getAppInfo() {
        const inspect = JSON.parse(execSync('cloudron inspect'));
        app = inspect.apps.filter(function (a) { return a.location.indexOf(LOCATION) === 0; })[0];
        expect(app).to.be.an('object');
    }

    async function login() {
        const response = await superagent.get(`https://${app.fqdn}`).auth(username, password);
        expect(response.text).to.contain('Copy here the URL of your video');
    }

    xit('build app', function () { execSync('cloudron build', EXEC_ARGS); });
    it('install app', function () { execSync(`cloudron install --location ${LOCATION}`, EXEC_ARGS); });
    it('can get app information', getAppInfo);

    it('can login', login);

    it('can restart app', function () { execSync(`cloudron restart --app ${app.id}`); });

    it('can login', login);

    it('backup app', function () { execSync(`cloudron backup create --app ${app.id}`); });
    it('restore app', function () {
        const backups = JSON.parse(execSync('cloudron backup list --raw'));
        execSync('cloudron uninstall --app ' + app.id, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
        execSync('cloudron install --location ' + LOCATION, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
        getAppInfo();
        execSync(`cloudron restore --backup ${backups[0].id} --app ${app.id}`, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });

    it('can login', login);

    it('move to different location', function () { execSync(`cloudron configure --app ${app.id} --location ${LOCATION}2`, EXEC_ARGS); });
    it('can get app information', getAppInfo);

    it('can login', login);

    it('uninstall app', function () { execSync(`cloudron uninstall --app ${app.id}`, EXEC_ARGS); });

    // test update
    it('can install app', function () { execSync(`cloudron install --appstore-id net.alltubedownload.cloudronapp --location ${LOCATION}`, EXEC_ARGS); });
    it('can get app information', getAppInfo);
    it('can login', login);

    it('can update', function () { execSync(`cloudron update --app ${LOCATION}`, EXEC_ARGS); });

    it('can login', login);

    it('uninstall app', function () { execSync(`cloudron uninstall --app ${app.id}`, EXEC_ARGS); });
});
