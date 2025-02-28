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

        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        my $TestUserLogin = $Helper->TestCustomerUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Customer',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        # go to customer preferences
        $Selenium->VerifiedGet("${ScriptAlias}customer.pl?Action=CustomerPreferences");

        # change test user password preference, input incorrect current password
        my $NewPw = "new" . $TestUserLogin;
        $Selenium->find_element( "#CurPw",  'css' )->send_keys("incorrect");
        $Selenium->find_element( "#NewPw",  'css' )->send_keys($NewPw);
        $Selenium->find_element( "#NewPw1", 'css' )->send_keys($NewPw);
        $Selenium->find_element( "#Update", 'css' )->VerifiedClick();

        # check for incorrect password update preferences message on screen
        my $IncorrectUpdateMessage = "The current password is not correct. Please try again!";
        $Self->True(
            index( $Selenium->get_page_source(), $IncorrectUpdateMessage ) > -1,
            'Customer incorrect preferences password - update'
        );

        # change test user password preference, correct input
        $Selenium->find_element( "#CurPw",  'css' )->send_keys($TestUserLogin);
        $Selenium->find_element( "#NewPw",  'css' )->send_keys($NewPw);
        $Selenium->find_element( "#NewPw1", 'css' )->send_keys($NewPw);
        $Selenium->find_element( "#Update", 'css' )->VerifiedClick();

        # check for correct password update preferences message on screen
        my $UpdateMessage = "Preferences updated successfully!";
        $Self->True(
            index( $Selenium->get_page_source(), $UpdateMessage ) > -1,
            'Customer preference password - updated'
        );
    }
);

$Self->DoneTesting();
