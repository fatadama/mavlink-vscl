/** @file
 *	@brief MAVLink comm protocol testsuite generated from vscl.xml
 *	@see http://qgroundcontrol.org/mavlink/
 */
#ifndef VSCL_TESTSUITE_H
#define VSCL_TESTSUITE_H

#ifdef __cplusplus
extern "C" {
#endif

#ifndef MAVLINK_TEST_ALL
#define MAVLINK_TEST_ALL

static void mavlink_test_vscl(uint8_t, uint8_t, mavlink_message_t *last_msg);

static void mavlink_test_all(uint8_t system_id, uint8_t component_id, mavlink_message_t *last_msg)
{

	mavlink_test_vscl(system_id, component_id, last_msg);
}
#endif




static void mavlink_test_vscl_test(uint8_t system_id, uint8_t component_id, mavlink_message_t *last_msg)
{
	mavlink_message_t msg;
        uint8_t buffer[MAVLINK_MAX_PACKET_LEN];
        uint16_t i;
	mavlink_vscl_test_t packet_in = {
		17235,
	};
	mavlink_vscl_test_t packet1, packet2;
        memset(&packet1, 0, sizeof(packet1));
        	packet1.dummy = packet_in.dummy;
        
        

        memset(&packet2, 0, sizeof(packet2));
	mavlink_msg_vscl_test_encode(system_id, component_id, &msg, &packet1);
	mavlink_msg_vscl_test_decode(&msg, &packet2);
        MAVLINK_ASSERT(memcmp(&packet1, &packet2, sizeof(packet1)) == 0);

        memset(&packet2, 0, sizeof(packet2));
	mavlink_msg_vscl_test_pack(system_id, component_id, &msg , packet1.dummy );
	mavlink_msg_vscl_test_decode(&msg, &packet2);
        MAVLINK_ASSERT(memcmp(&packet1, &packet2, sizeof(packet1)) == 0);

        memset(&packet2, 0, sizeof(packet2));
	mavlink_msg_vscl_test_pack_chan(system_id, component_id, MAVLINK_COMM_0, &msg , packet1.dummy );
	mavlink_msg_vscl_test_decode(&msg, &packet2);
        MAVLINK_ASSERT(memcmp(&packet1, &packet2, sizeof(packet1)) == 0);

        memset(&packet2, 0, sizeof(packet2));
        mavlink_msg_to_send_buffer(buffer, &msg);
        for (i=0; i<mavlink_msg_get_send_buffer_length(&msg); i++) {
        	comm_send_ch(MAVLINK_COMM_0, buffer[i]);
        }
	mavlink_msg_vscl_test_decode(last_msg, &packet2);
        MAVLINK_ASSERT(memcmp(&packet1, &packet2, sizeof(packet1)) == 0);
        
        memset(&packet2, 0, sizeof(packet2));
	mavlink_msg_vscl_test_send(MAVLINK_COMM_1 , packet1.dummy );
	mavlink_msg_vscl_test_decode(last_msg, &packet2);
        MAVLINK_ASSERT(memcmp(&packet1, &packet2, sizeof(packet1)) == 0);
}

static void mavlink_test_vscl(uint8_t system_id, uint8_t component_id, mavlink_message_t *last_msg)
{
	mavlink_test_vscl_test(system_id, component_id, last_msg);
}

#ifdef __cplusplus
}
#endif // __cplusplus
#endif // VSCL_TESTSUITE_H
