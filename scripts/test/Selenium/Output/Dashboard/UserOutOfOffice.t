# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2021 Rother OSS GmbH, https://otobo.de/
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# --

use strict;
use warnings;
use utf8;

# Set up the test driver $Self when we are running as a standalone script.
use Kernel::System::UnitTest::RegisterDriver;

use vars (qw($Self));

# get selenium object
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        # get helper object
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # make sure that UserOutOfOffice is enabled
        my %UserOutOfOfficeSysConfig = $Kernel::OM->Get('Kernel::System::SysConfig')->SettingGet(
            Name    => 'DashboardBackend###0390-UserOutOfOffice',
            Default => 1,
        );

        # enable UserOutOfOffice and set it to load as default plugin
        $Helper->ConfigSettingChange(
            Valid => 1,
            Key   => 'DashboardBackend###0390-UserOutOfOffice',
            Value => $UserOutOfOfficeSysConfig{EffectiveValue},

        );

        # create test user and login
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # get user object
        my $UserObject = $Kernel::OM->Get('Kernel::System::User');

        # get test user ID
        my $TestUserID = $UserObject->UserLookup(
            UserLogin => $TestUserLogin,
        );

        # get time object
        my $DTObj    = $Kernel::OM->Create('Kernel::System::DateTime');
        my $DTValues = $DTObj->Get();

        # create OutOfOffice params
        my @OutOfOfficeTime = (
            {
                Key   => 'OutOfOffice',
                Value => 1,
            },
            {
                Key   => 'OutOfOfficeStartYear',
                Value => $DTValues->{Year},
            },
            {
                Key   => 'OutOfOfficeEndYear',
                Value => $DTValues->{Year} + 1,
            },
            {
                Key   => 'OutOfOfficeStartMonth',
                Value => $DTValues->{Month},
            },
            {
                Key   => 'OutOfOfficeEndMonth',
                Value => $DTValues->{Month},
            },
            {
                Key   => 'OutOfOfficeStartDay',
                Value => $DTValues->{Day},
            },
            {
                Key   => 'OutOfOfficeEndDay',
                Value => $DTValues->{Day},
            },
        );

        # set OutOfOffice preference
        for my $OutOfOfficePreference (@OutOfOfficeTime) {
            $UserObject->SetPreferences(
                UserID => $TestUserID,
                Key    => $OutOfOfficePreference->{Key},
                Value  => $OutOfOfficePreference->{Value},
            );
        }

        # clean up dashboard cache and refresh screen
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp( Type => 'Dashboard' );
        $Selenium->VerifiedRefresh();

        # test OutOfOffice plugin
        my $ExpectedResult = sprintf(
            "$TestUserLogin until %02d/%02d/%d",
            $DTValues->{Month},
            $DTValues->{Day},
            $DTValues->{Year} + 1,
        );
        $Self->True(
            index( $Selenium->get_page_source(), $ExpectedResult ) > -1,
            "OutOfOffice message - found on screen"
        );

    }
);

$Self->DoneTesting();
