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

# get config object
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

# do not checkmx
$Kernel::OM->Get('Kernel::System::UnitTest::Helper')->ConfigSettingChange(
    Valid => 1,
    Key   => 'CheckEmailAddresses',
    Value => 0,
);

# get selenium object
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

# this test is to check that when AgentTicketPhone is loaded already with
# customer data on it (like when doing Split), the dropdown of Service is
# prefilled with the correct data. This is because of bug
# http://bugs.otrs.org/show_bug.cgi?id=7060

$Selenium->RunTest(
    sub {

        # get helper object
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # update sysconfig settings
        $Helper->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::Service',
            Value => 1,
        );

        # create test user and login
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => ['users'],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # create a customer and a ticket from that customer as previous
        # steps to do the selenium testing

        my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');
        my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');

        # create a test customer
        my $TestUserCustomer = $Helper->TestCustomerUserCreate()
            || die "Did not get test customer user";

        # create a ticket from the just created customer
        my $TicketID = $TicketObject->TicketCreate(
            Title        => 'Selenium Test-Some Ticket Title',
            Queue        => 'Raw',
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'closed successful',
            CustomerUser => $TestUserCustomer,
            OwnerID      => 1,
            UserID       => 1,
        );

        $Self->True(
            $TicketID,
            "Ticket is created - $TicketID",
        );

        my $TestService = "Service-" . $Helper->GetRandomID();

        # create a test service
        my $ServiceID = $ServiceObject->ServiceAdd(
            Name    => $TestService,
            Comment => 'Selenium Test Service',
            ValidID => 1,
            UserID  => 1,
        );

        $Self->True(
            $ServiceID,
            "Service is created - $ServiceID",
        );

        # allow access to the just created service to the test user
        $ServiceObject->CustomerUserServiceMemberAdd(
            CustomerUserLogin => $TestUserCustomer,
            ServiceID         => $ServiceID,
            Active            => 1,
            UserID            => 1,
        );

        # create an article for the test ticket
        my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForChannel(
            ChannelName => 'Internal',
        );
        my $ArticleID = $ArticleBackendObject->ArticleCreate(
            TicketID             => $TicketID,
            IsVisibleForCustomer => 0,
            SenderType           => 'agent',
            Subject              => 'Selenium test',
            Body                 => 'Just a test body for selenium testing',
            Charset              => 'ISO-8859-15',
            MimeType             => 'text/plain',
            HistoryType          => 'AddNote',
            HistoryComment       => 'Selenium testing',
            UserID               => 1,
        );

        $Self->True(
            $ArticleID,
            "Article is created - $ArticleID",
        );

        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        # real selenium test start
        # open the page that clicking on Split link of the zoom view of the
        # just created ticket would open
        $Selenium->VerifiedGet(
            "${ScriptAlias}index.pl?Action=AgentTicketPhone;TicketID=$TicketID;ArticleID=$ArticleID"
        );

        # verify that the services dropdown has just created service
        $Self->True(
            $Selenium->find_element( "select#ServiceID option[value='$ServiceID']", 'css' ),
            "The services dropdown has created service - $TestService",
        );

        # get DB object
        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

        # clean up test data
        # delete the test ticket
        my $Success = $TicketObject->TicketDelete(
            TicketID => $TicketID,
            UserID   => 1,
        );

        # Ticket deletion could fail if apache still writes to ticket history. Try again in this case.
        if ( !$Success ) {
            sleep 3;
            $Success = $TicketObject->TicketDelete(
                TicketID => $TicketID,
                UserID   => 1,
            );
        }

        $Self->True(
            $Success,
            "Deleted ticket - $TicketID",
        );

        # delete the test service
        $Success = $DBObject->Do(
            SQL => "DELETE FROM service_customer_user WHERE service_id = $ServiceID",
        );
        $Self->True(
            $Success,
            "ServiceCustomerUser deleted - $ServiceID",
        );

        $Success = $DBObject->Do(
            SQL => "DELETE FROM service WHERE id = $ServiceID",
        );
        $Self->True(
            $Success,
            "Deleted Service - $ServiceID",
        );

        # make sure the cache is correct.
        for my $Cache (
            qw (Service Ticket)
            )
        {
            $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
                Type => $Cache,
            );
        }
    }
);

$Self->DoneTesting();
